package com.anandhakrishnan.codeblock.downloader_flutter

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import android.widget.Toast
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import androidx.core.net.toUri
import kotlinx.coroutines.withContext
import java.util.concurrent.atomic.AtomicInteger

/**
 * A helper class for downloading single files using Android DownloadManager.
 */
object DownloadManagerFlutter {

    fun downloadSingleFile(
        context: Context,
        url: String,
        fileName: String,
        showToast: Boolean,
        completion: (String) -> Unit,
        progressCallback: (Map<String, Any>) -> Unit) {

        CoroutineScope(Dispatchers.IO).launch {

            try {
                val request = DownloadManager.Request(url.toUri())
                    .setTitle(fileName)
                    .setDescription("Downloading file...")
                    .setAllowedOverMetered(true)
                    .setAllowedOverRoaming(true)
                    .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                    .setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)

                val downloadManager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
                val downloadId = downloadManager.enqueue(request)
                trackDownloadProgress(
                    context,
                    downloadId,
                    showToast,
                    fileName,
                    progressCallback
                )

                // Notify success back to Flutter
                CoroutineScope(Dispatchers.Main).launch {
                    if (showToast) {
                        Toast.makeText(context, "Download started...", Toast.LENGTH_SHORT).show()
                    }
                    progressCallback(
                        DownloadProgress.statusStarted(
                            fileName = fileName
                        )
                    )
                }

            } catch (e: Exception) {
                e.printStackTrace()
                CoroutineScope(Dispatchers.Main).launch {
                    if (showToast) {
                        Toast.makeText(context, "Download failed", Toast.LENGTH_SHORT).show()
                    }
                    progressCallback(
                        DownloadProgress.statusError(
                            fileName = fileName,
                            message = e.message.orEmpty()
                        )
                    )
                }
            }
        }
        // Inform Flutter that all downloads have been initiated
        CoroutineScope(Dispatchers.Main).launch {
            completion("Single File Download Started")
        }
    }

    fun downloadMultipleFiles(
        context: Context,
        urls: List<String>,
        fileNames: List<String>,
        showToast: Boolean,
        completion: (String) -> Unit,
        progressCallback: (Map<String, Any>) -> Unit) {

        CoroutineScope(Dispatchers.IO).launch {
            val downloadManager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
            var filename = ""

            for (i in urls.indices) {
                val url = urls[i]
                val fileName = fileNames[i]
                filename = fileName
                try {
                    val request = DownloadManager.Request(url.toUri())
                        .setTitle(fileName)
                        .setDescription("Downloading $fileName")
                        .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                        .setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
                        .setAllowedOverMetered(true)
                        .setAllowedOverRoaming(true)

                    val downloadId = downloadManager.enqueue(request)
                    trackDownloadProgress(
                        context,
                        downloadId,
                        showToast,
                        fileName,
                        progressCallback
                    )

                    CoroutineScope(Dispatchers.Main).launch {
                        // Notify success back to Flutter
                        if (showToast) {
                            Toast.makeText(context, "Download started...", Toast.LENGTH_SHORT).show()
                        }
                        progressCallback(
                            DownloadProgress.statusStarted(
                                fileName = fileName
                            )
                        )
                    }

                } catch (e: Exception) {
                    e.printStackTrace()
                    CoroutineScope(Dispatchers.Main).launch {
                        // Notify success back to Flutter
                        if (showToast) {
                            Toast.makeText(context, "Download failed", Toast.LENGTH_SHORT).show()
                        }
                        progressCallback(
                            DownloadProgress.statusError(
                                fileName = fileName,
                                message = e.message.orEmpty()
                            )
                        )
                    }
                }
            }
            // Inform Flutter that all downloads have been initiated
            CoroutineScope(Dispatchers.Main).launch {
                completion("Multiple File Download Started")
            }
        }
    }

    fun trackDownloadProgress(
        context: Context,
        downloadId: Long,
        showToast: Boolean,
        fileName: String,
        progressCallback: (Map<String, Any>) -> Unit) {

        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val query = DownloadManager.Query().setFilterById(downloadId)
        var downloading = true

        CoroutineScope(Dispatchers.IO).launch {
            while (downloading) {
                delay(1000)
                val cursor = manager.query(query)
                if (cursor != null && cursor.moveToFirst()) {
                    val status = cursor.getInt(cursor.getColumnIndexOrThrow(
                        DownloadManager.COLUMN_STATUS
                    ))

                    val bytesDownloaded =
                        cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR))
                    val bytesTotal =
                        cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES))

                    if (bytesTotal > 0) {
                        val progress = (bytesDownloaded * 100L / bytesTotal).toInt()

                        CoroutineScope(Dispatchers.Main).launch {
                            progressCallback(
                                DownloadProgress.statusProgress(
                                    fileName = fileName,
                                    progress = progress
                                )
                            )
                        }
                    }

                    when (status) {
                        DownloadManager.STATUS_SUCCESSFUL -> {
                            downloading = false
                            CoroutineScope(Dispatchers.Main).launch {
                                // Notify success back to Flutter
                                if (showToast) {
                                    Toast.makeText(context, "Download completed!", Toast.LENGTH_SHORT).show()
                                }
                                progressCallback(
                                    DownloadProgress.statusSuccess(
                                        fileName = fileName
                                    )
                                )
                                progressCallback(
                                    DownloadProgress.statusCompleted(
                                        fileName = fileName)
                                )
                            }
                        }

                        DownloadManager.STATUS_FAILED -> {
                            val reason = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON))
                            downloading = false
                            CoroutineScope(Dispatchers.Main).launch {
                                // Notify success back to Flutter
                                if (showToast) {
                                    Toast.makeText(context, "Download failed", Toast.LENGTH_LONG).show()
                                }
                                progressCallback(
                                    DownloadProgress.statusFailed(
                                        fileName = fileName,
                                        message = "$reason"

                                    )
                                )
                            }
                        }
                    }
                    cursor.close()
                } else {
                    downloading = false
                }
            }
        }
    }
}
