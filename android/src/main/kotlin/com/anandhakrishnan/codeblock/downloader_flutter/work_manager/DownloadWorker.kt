package com.anandhakrishnan.codeblock.downloader_flutter.work_manager

import android.content.Context
import android.net.Uri
import android.os.Build
import androidx.core.net.toUri
import androidx.work.CoroutineWorker
import androidx.work.ForegroundInfo
import androidx.work.WorkInfo
import androidx.work.WorkerParameters
import com.anandhakrishnan.codeblock.downloader_flutter_android.database.DownloaderDatabase
import com.anandhakrishnan.codeblock.downloader_flutter_android.database.entity.DownloadEntity
import com.anandhakrishnan.codeblock.downloader_flutter_android.database.entity.DownloadStatus
import com.anandhakrishnan.codeblock.downloader_flutter_android.database.repository.DownloadRepository
import com.anandhakrishnan.codeblock.downloader_flutter_android.database.repository.DownloadRepositoryImpl
import com.anandhakrishnan.codeblock.downloader_flutter_android.notification.DownloadNotificationHelper
import com.anandhakrishnan.codeblock.downloader_flutter_android.storage.StorageHelper
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.MalformedURLException
import java.net.URL

class DownloadWorker(
    appContext: Context,
    params: WorkerParameters
) : CoroutineWorker(appContext, params) {

    private val repository: DownloadRepository = DownloadRepositoryImpl(
        DownloaderDatabase.getInstance(appContext).downloadDao()
    )
    private val notificationHelper = DownloadNotificationHelper(appContext)
    private val storageHelper = StorageHelper(appContext)

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val downloadId = inputData.getLong(KEY_DOWNLOAD_ID, -1L)
        if (downloadId == -1L) return@withContext Result.failure()

        val entity = repository.getDownloadById(downloadId).getOrNull()
            ?: return@withContext Result.failure()

        notificationHelper.dismissStatusNotification(downloadId)

        val runningEntity = entity.copy(
            status = DownloadStatus.RUNNING,
            retried = runAttemptCount,
            errorMessage = null
        )
        setForeground(notificationHelper.createForegroundInfo(runningEntity))
        repository.updateDownload(runningEntity)

        try {
            val resultUri = downloadFileWithResume(runningEntity)

            val latest = repository.getDownloadById(downloadId).getOrNull() ?: runningEntity
            val completedEntity = latest.copy(
                status = DownloadStatus.COMPLETED,
                percentage = 100f,
                workId = null,
                fileUri = resultUri.toString(),
                errorMessage = null
            )
            repository.updateDownload(completedEntity)
            notificationHelper.showCompletedNotification(completedEntity)
            if (completedEntity.isOneByOne) {
                DownloadWorkScheduler(applicationContext, repository).scheduleNextSequentialIfIdle()
            }
            Result.success()

        } catch (e: CancellationException) {
            withContext(NonCancellable) {
                val latest = repository.getDownloadById(downloadId).getOrNull()
                // If status is still RUNNING, cancellation came from OS/constraints rather than user Pause/Stop/Delete
                if (latest != null && latest.status == DownloadStatus.RUNNING) {
                    val constraintMsg = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        when (stopReason) {
                            WorkInfo.STOP_REASON_CONSTRAINT_CONNECTIVITY ->
                                "Network disconnected. Waiting to resume..."
                            WorkInfo.STOP_REASON_CONSTRAINT_BATTERY_NOT_LOW ->
                                "Battery low. Waiting to resume..."
                            else ->
                                "Connection interrupted. Waiting to resume..."
                        }
                    } else {
                        "Connection interrupted. Waiting to resume..."
                    }

                    val waitingEntity = latest.copy(
                        status = DownloadStatus.QUEUED,
                        errorMessage = constraintMsg
                    )
                    repository.updateDownload(waitingEntity)
                    notificationHelper.showRetryingNotification(waitingEntity, constraintMsg)
                }
            }
            throw e

        } catch (e: Exception) {
            val latest = repository.getDownloadById(downloadId).getOrNull() ?: runningEntity
            val errorMsg = e.message?.takeIf { it.isNotBlank() }
                ?: e.javaClass.simpleName.ifBlank { "Download error" }

            val isPermanentError = e is MalformedURLException || e is NonRetryableHttpException
            val canRetry = !isPermanentError && runAttemptCount < latest.maxRetry

            if (canRetry) {
                val retryingEntity = latest.copy(
                    status = DownloadStatus.QUEUED,
                    retried = runAttemptCount + 1,
                    errorMessage = errorMsg
                )
                repository.updateDownload(retryingEntity)
                notificationHelper.showRetryingNotification(retryingEntity, errorMsg)
                Result.retry()
            } else {
                val failedEntity = latest.copy(
                    status = DownloadStatus.FAILED,
                    workId = null,
                    errorMessage = errorMsg
                )
                repository.updateDownload(failedEntity)
                notificationHelper.showFailedNotification(failedEntity, errorMsg)
                if (failedEntity.isOneByOne) {
                    DownloadWorkScheduler(applicationContext, repository).scheduleNextSequentialIfIdle()
                }
                Result.failure()
            }
        }
    }

    private suspend fun downloadFileWithResume(entity: DownloadEntity): Uri {
        val existingBytes = entity.downloadedBytes
        val existingUri = entity.fileUri?.toUri()

        val connection = (URL(entity.url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 15_000
            readTimeout = 30_000
            instanceFollowRedirects = true
            if (existingBytes > 0L && existingUri != null) {
                setRequestProperty("Range", "bytes=$existingBytes-")
            }
        }

        connection.connect()

        val responseCode = connection.responseCode
        if (responseCode !in 200..299 && responseCode != HttpURLConnection.HTTP_PARTIAL) {
            connection.disconnect()
            if (responseCode in 400..499) {
                throw NonRetryableHttpException("Server returned HTTP $responseCode")
            } else {
                throw IllegalStateException("Server returned HTTP $responseCode")
            }
        }

        val isResuming = responseCode == HttpURLConnection.HTTP_PARTIAL && existingUri != null
        val contentLength = connection.contentLengthLong
        val totalBytes = if (isResuming && contentLength > 0) {
            existingBytes + contentLength
        } else if (contentLength > 0) {
            contentLength
        } else {
            entity.totalBytes
        }

        val mimeType = connection.contentType?.substringBefore(";") ?: "application/octet-stream"
        var activeEntity = if (isResuming) {
            entity.copy(totalBytes = totalBytes)
        } else {
            val newUri = storageHelper.createTargetUri(entity.fileName, mimeType)
            entity.copy(
                status = DownloadStatus.RUNNING,
                fileUri = newUri.toString(),
                mimeType = mimeType,
                totalBytes = totalBytes,
                downloadedBytes = 0L
            ).also { repository.updateDownload(it) }
        }

        val targetUri = activeEntity.fileUri!!.toUri()
        var downloadedSoFar = if (isResuming) existingBytes else 0L
        var lastUpdateTime = System.currentTimeMillis()

        connection.inputStream.use { input ->
            storageHelper.openOutputStream(targetUri, isResuming).use { output ->
                val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                var bytesRead: Int

                while (input.read(buffer).also { bytesRead = it } != -1) {
                    if (isStopped) {
                        throw CancellationException("Worker stopped")
                    }

                    output.write(buffer, 0, bytesRead)
                    downloadedSoFar += bytesRead

                    val now = System.currentTimeMillis()
                    if (now - lastUpdateTime >= 250L) {
                        lastUpdateTime = now
                        val percentage = if (totalBytes > 0L) {
                            (downloadedSoFar * 100f / totalBytes).coerceIn(0f, 100f)
                        } else {
                            0f
                        }
                        repository.updateProgress(entity.id, percentage, downloadedSoFar, totalBytes)

                        activeEntity = activeEntity.copy(
                            percentage = percentage,
                            downloadedBytes = downloadedSoFar,
                            totalBytes = totalBytes
                        )
                        setForeground(notificationHelper.createForegroundInfo(activeEntity))
                    }
                }
                output.flush()
            }
        }

        connection.disconnect()
        storageHelper.finalizeFile(targetUri)
        val finalTotal = totalBytes.coerceAtLeast(downloadedSoFar)
        repository.updateProgress(
            id = entity.id,
            percentage = 100f,
            downloadedBytes = downloadedSoFar,
            totalBytes = finalTotal
        )
        return targetUri
    }

    override suspend fun getForegroundInfo(): ForegroundInfo {
        val downloadId = inputData.getLong(KEY_DOWNLOAD_ID, 0L)
        return notificationHelper.createFallbackForegroundInfo(downloadId)
    }

    private class NonRetryableHttpException(message: String) : IllegalStateException(message)

    companion object {
        const val KEY_DOWNLOAD_ID = "key_download_id"
    }
}