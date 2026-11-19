package com.anandhakrishnan.codeblock.downloader_flutter.work_manager

import android.content.Context
import androidx.core.net.toUri
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequest
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import androidx.work.workDataOf
import com.anandhakrishnan.codeblock.downloader_flutter.database.entity.DownloadEntity
import com.anandhakrishnan.codeblock.downloader_flutter.database.entity.DownloadStatus
import com.anandhakrishnan.codeblock.downloader_flutter.database.repository.DownloadRepository
import com.anandhakrishnan.codeblock.downloader_flutter.notification.DownloadNotificationHelper
import com.anandhakrishnan.codeblock.downloader_flutter.storage.StorageHelper
import com.anandhakrishnan.codeblock.downloader_flutter.util.ToastHelper
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.util.UUID
import java.util.concurrent.TimeUnit

class DownloadWorkScheduler(
    context: Context,
    private val repository: DownloadRepository
) {
    private val appContext = context.applicationContext
    private val workManager = WorkManager.getInstance(appContext)
    private val notificationHelper = DownloadNotificationHelper(appContext)
    private val storageHelper = StorageHelper(appContext)
    private val toastHelper = ToastHelper(appContext)

    suspend fun enqueueDownload(
        url: String,
        fileName: String,
        isImmediate: Boolean = true,
        isWifiOnly: Boolean = false,
        isPowerSavingEnabled: Boolean = false,
        isOneByOne: Boolean = false,
        showToast: Boolean = false,
        maxRetry: Int = 3
    ): Result<Long> {
        val initialStatus = if (isImmediate) DownloadStatus.QUEUED else DownloadStatus.PAUSED

        val entity = DownloadEntity(
            fileName = fileName,
            url = url,
            status = initialStatus,
            maxRetry = maxRetry,
            isImmediate = isImmediate,
            isWifiOnly = isWifiOnly,
            isPowerSavingEnabled = isPowerSavingEnabled,
            isOneByOne = isOneByOne,
            showToast = showToast
        )

        return repository.insertDownload(entity).onSuccess { insertedId ->
            val savedEntity = entity.copy(id = insertedId)
            if (isImmediate) {
                toastHelper.show(showToast, "Download queued: $fileName")
                if (isOneByOne) {
                    scheduleNextSequentialIfIdle()
                } else {
                    scheduleWorkerForEntity(savedEntity)
                }
            } else {
                toastHelper.show(showToast, "Added to queue (Paused): $fileName")
                notificationHelper.showPausedNotification(savedEntity)
            }
        }
    }

    suspend fun enqueueMultipleDownloads(
        items: List<Pair<String, String>>,
        isImmediate: Boolean = true,
        isWifiOnly: Boolean = false,
        isPowerSavingEnabled: Boolean = false,
        isOneByOne: Boolean = false,
        showToast: Boolean = false,
        maxRetry: Int = 3
    ) {
        if (!isOneByOne) {
            items.forEach { (url, fileName) ->
                enqueueDownload(
                    url = url,
                    fileName = fileName,
                    isImmediate = isImmediate,
                    isWifiOnly = isWifiOnly,
                    isPowerSavingEnabled = isPowerSavingEnabled,
                    isOneByOne = false,
                    showToast = false,
                    maxRetry = maxRetry
                )
            }
            toastHelper.show(
                showToast,
                if (isImmediate) "Batch download queued (${items.size} files)"
                else "Batch added to queue (${items.size} files)"
            )
            return
        }

        val initialStatus = if (isImmediate) DownloadStatus.QUEUED else DownloadStatus.PAUSED
        items.forEach { (url, fileName) ->
            val entity = DownloadEntity(
                fileName = fileName,
                url = url,
                status = initialStatus,
                maxRetry = maxRetry,
                isImmediate = isImmediate,
                isWifiOnly = isWifiOnly,
                isPowerSavingEnabled = isPowerSavingEnabled,
                isOneByOne = true,
                showToast = showToast
            )
            repository.insertDownload(entity).onSuccess { insertedId ->
                if (!isImmediate) {
                    notificationHelper.showPausedNotification(entity.copy(id = insertedId))
                }
            }
        }

        toastHelper.show(
            showToast,
            if (isImmediate) "Sequential download queued (${items.size} files)"
            else "Sequential batch paused (${items.size} files)"
        )

        if (isImmediate) {
            scheduleNextSequentialIfIdle()
        }
    }

    suspend fun scheduleNextSequentialIfIdle() {
        sequentialMutex.withLock {
            val activeCount = repository.countActiveSequentialDownloads().getOrNull() ?: 0
            if (activeCount > 0) return

            val nextEntity = repository.getNextSequentialDownload().getOrNull() ?: return
            if (nextEntity.workId != null) return

            scheduleWorkerForEntity(nextEntity)
        }
    }

    suspend fun pauseDownload(downloadId: Long, showToastOverride: Boolean? = null) {
        val entity = repository.getDownloadById(downloadId).getOrNull() ?: return
        entity.workId?.let { id ->
            workManager.cancelWorkById(UUID.fromString(id))
        }
        val pausedEntity = entity.copy(
            status = DownloadStatus.PAUSED,
            workId = null
        )
        repository.updateDownload(pausedEntity)
        notificationHelper.showPausedNotification(pausedEntity)
        toastHelper.show(showToastOverride ?: entity.showToast, "Paused: ${entity.fileName}")

        if (entity.isOneByOne) {
            scheduleNextSequentialIfIdle()
        }
    }

    suspend fun resumeDownload(downloadId: Long, showToastOverride: Boolean? = null) {
        val entity = repository.getDownloadById(downloadId).getOrNull() ?: return
        if (entity.status == DownloadStatus.COMPLETED) return

        notificationHelper.dismissStatusNotification(downloadId)
        val updatedEntity = entity.copy(
            status = DownloadStatus.QUEUED,
            workId = null,
            errorMessage = null
        )
        repository.updateDownload(updatedEntity)
        toastHelper.show(showToastOverride ?: entity.showToast, "Resumed: ${entity.fileName}")

        if (updatedEntity.isOneByOne) {
            scheduleNextSequentialIfIdle()
        } else {
            scheduleWorkerForEntity(updatedEntity)
        }
    }

    suspend fun cancelDownload(downloadId: Long, showToastOverride: Boolean? = null) {
        val entity = repository.getDownloadById(downloadId).getOrNull() ?: return
        entity.workId?.let { id ->
            workManager.cancelWorkById(UUID.fromString(id))
        }
        val stoppedEntity = entity.copy(
            status = DownloadStatus.CANCELLED,
            workId = null
        )
        repository.updateDownload(stoppedEntity)
        notificationHelper.showStoppedNotification(stoppedEntity)
        toastHelper.show(showToastOverride ?: entity.showToast, "Stopped: ${entity.fileName}")

        if (entity.isOneByOne) {
            scheduleNextSequentialIfIdle()
        }
    }

    suspend fun deleteDownload(downloadId: Long, showToastOverride: Boolean? = null) {
        val entity = repository.getDownloadById(downloadId).getOrNull() ?: return
        entity.workId?.let { id ->
            workManager.cancelWorkById(UUID.fromString(id))
        }
        entity.fileUri?.let { uriString ->
            storageHelper.deleteFile(uriString.toUri())
        }
        repository.deleteDownload(entity)
        notificationHelper.dismissAllNotifications(downloadId)
        toastHelper.show(showToastOverride ?: entity.showToast, "Deleted: ${entity.fileName}")

        if (entity.isOneByOne) {
            scheduleNextSequentialIfIdle()
        }
    }

    private suspend fun scheduleWorkerForEntity(entity: DownloadEntity) {
        val request = buildWorkRequest(entity)
        repository.updateDownload(entity.copy(workId = request.id.toString()))

        workManager.enqueueUniqueWork(
            "download_job_${entity.id}",
            ExistingWorkPolicy.REPLACE,
            request
        )
    }

    private fun buildWorkRequest(entity: DownloadEntity): OneTimeWorkRequest {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(
                if (entity.isWifiOnly) NetworkType.UNMETERED else NetworkType.CONNECTED
            )
            .setRequiresBatteryNotLow(entity.isPowerSavingEnabled)
            .build()

        return OneTimeWorkRequestBuilder<DownloadWorker>()
            .setConstraints(constraints)
            .setInputData(workDataOf(DownloadWorker.KEY_DOWNLOAD_ID to entity.id))
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 10, TimeUnit.SECONDS)
            .apply {
                if (entity.isImmediate) {
                    setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
                }
            }
            .build()
    }

    companion object {
        private val sequentialMutex = Mutex()
    }
}