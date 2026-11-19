package com.anandhakrishnan.codeblock.downloader_flutter.notification

import android.Manifest
import android.R
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.work.ForegroundInfo
import com.anandhakrishnan.codeblock.downloader_flutter_android.database.entity.DownloadEntity
import java.util.Locale

class DownloadNotificationHelper(private val context: Context) {

    private val notificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    init {
        createNotificationChannel()
    }

    fun canShowNotifications(): Boolean {
        val hasRuntimePermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
        return hasRuntimePermission && NotificationManagerCompat.from(context).areNotificationsEnabled()
    }

    /**
     * Active foreground notification while DownloadWorker is running.
     * Buttons: Pause | Stop | Delete
     */
    fun createForegroundInfo(entity: DownloadEntity): ForegroundInfo {
        val progress = entity.percentage.toInt().coerceIn(0, 100)
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.stat_sys_download)
            .setContentTitle(entity.fileName)
            .setOngoing(true)
            .setOnlyAlertOnce(true)

        if (canShowNotifications()) {
            val sizeText = if (entity.totalBytes > 0L) {
                "${formatBytes(entity.downloadedBytes)} / ${formatBytes(entity.totalBytes)}"
            } else {
                formatBytes(entity.downloadedBytes)
            }
            val contentText = if (progress > 0) {
                "Downloading $progress% • $sizeText"
            } else {
                "Starting download..."
            }

            builder
                .setContentText(contentText)
                .setSubText(buildPreferenceSummary(entity))
                .setProgress(100, progress, entity.totalBytes <= 0L)
                .addAction(
                    R.drawable.ic_media_pause,
                    "Pause",
                    createActionPendingIntent(entity.id, DownloadActionReceiver.ACTION_PAUSE, 1)
                )
                .addAction(
                    R.drawable.ic_delete,
                    "Stop",
                    createActionPendingIntent(entity.id, DownloadActionReceiver.ACTION_STOP, 3)
                )
                .addAction(
                    R.drawable.ic_menu_delete,
                    "Delete",
                    createActionPendingIntent(entity.id, DownloadActionReceiver.ACTION_DELETE, 4)
                )
        } else {
            builder.setContentText("Downloading...")
        }

        val notificationId = entity.id.toInt()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ForegroundInfo(
                notificationId,
                builder.build(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            )
        } else {
            ForegroundInfo(notificationId, builder.build())
        }
    }

    fun createFallbackForegroundInfo(downloadId: Long): ForegroundInfo {
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.stat_sys_download)
            .setContentTitle("Preparing download...")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ForegroundInfo(
                downloadId.toInt(),
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            )
        } else {
            ForegroundInfo(downloadId.toInt(), notification)
        }
    }

    /**
     * Persistent notification when paused.
     * Buttons: Continue | Stop | Delete
     */
    fun showPausedNotification(entity: DownloadEntity) {
        if (!canShowNotifications()) return

        val progress = entity.percentage.toInt().coerceIn(0, 100)
        val sizeText = "${formatBytes(entity.downloadedBytes)} / ${formatBytes(entity.totalBytes)}"

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_media_pause)
            .setContentTitle(entity.fileName)
            .setContentText("Paused at $progress% • $sizeText")
            .setSubText(buildPreferenceSummary(entity))
            .setProgress(100, progress, false)
            .setOnlyAlertOnce(true)
            .addAction(
                R.drawable.ic_media_play,
                "Continue",
                createActionPendingIntent(entity.id, DownloadActionReceiver.ACTION_CONTINUE, 2)
            )
            .addAction(
                R.drawable.ic_delete,
                "Stop",
                createActionPendingIntent(entity.id, DownloadActionReceiver.ACTION_STOP, 3)
            )
            .addAction(
                R.drawable.ic_menu_delete,
                "Delete",
                createActionPendingIntent(entity.id, DownloadActionReceiver.ACTION_DELETE, 4)
            )
            .build()

        notificationManager.notify(statusNotificationId(entity.id), notification)
    }

    /**
     * Persistent notification when an error occurs and WorkManager is waiting to retry or regain network.
     * Buttons: Stop | Delete
     */
    fun showRetryingNotification(entity: DownloadEntity, reason: String) {
        if (!canShowNotifications()) return

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.stat_notify_error)
            .setContentTitle("Error: ${entity.fileName}")
            .setContentText("$reason (Retry ${entity.retried}/${entity.maxRetry})")
            .setSubText(buildPreferenceSummary(entity))
            .setOnlyAlertOnce(true)
            .addAction(
                R.drawable.ic_delete,
                "Stop Retry",
                createActionPendingIntent(entity.id, DownloadActionReceiver.ACTION_STOP, 3)
            )
            .addAction(
                R.drawable.ic_menu_delete,
                "Delete",
                createActionPendingIntent(entity.id, DownloadActionReceiver.ACTION_DELETE, 4)
            )
            .build()

        notificationManager.notify(statusNotificationId(entity.id), notification)
    }

    /**
     * Persistent notification when stopped by user.
     * Buttons: Continue | Delete
     */
    fun showStoppedNotification(entity: DownloadEntity) {
        if (!canShowNotifications()) return

        val progress = entity.percentage.toInt().coerceIn(0, 100)
        val sizeText = "${formatBytes(entity.downloadedBytes)} / ${formatBytes(entity.totalBytes)}"

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_delete)
            .setContentTitle(entity.fileName)
            .setContentText("Stopped at $progress% • $sizeText")
            .setSubText(buildPreferenceSummary(entity))
            .addAction(
                R.drawable.ic_media_play,
                "Continue",
                createActionPendingIntent(entity.id, DownloadActionReceiver.ACTION_CONTINUE, 2)
            )
            .addAction(
                R.drawable.ic_menu_delete,
                "Delete",
                createActionPendingIntent(entity.id, DownloadActionReceiver.ACTION_DELETE, 4)
            )
            .build()

        notificationManager.notify(statusNotificationId(entity.id), notification)
    }

    /**
     * Persistent notification when download finishes.
     * Buttons: Delete
     */
    fun showCompletedNotification(entity: DownloadEntity) {
        if (!canShowNotifications()) return

        val finalSize = formatBytes(entity.totalBytes.coerceAtLeast(entity.downloadedBytes))
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.stat_sys_download_done)
            .setContentTitle(entity.fileName)
            .setContentText("Download complete • $finalSize")
            .setSubText(buildPreferenceSummary(entity))
            .addAction(
                R.drawable.ic_menu_delete,
                "Delete",
                createActionPendingIntent(entity.id, DownloadActionReceiver.ACTION_DELETE, 4)
            )
            .build()

        notificationManager.notify(statusNotificationId(entity.id), notification)
    }

    /**
     * Persistent notification when download fails permanently.
     * Buttons: Retry | Delete
     */
    fun showFailedNotification(entity: DownloadEntity, reason: String) {
        if (!canShowNotifications()) return

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.stat_notify_error)
            .setContentTitle("Failed: ${entity.fileName}")
            .setContentText(reason)
            .setSubText("Retries: ${entity.retried}/${entity.maxRetry}")
            .addAction(
                R.drawable.ic_media_play,
                "Retry",
                createActionPendingIntent(entity.id, DownloadActionReceiver.ACTION_CONTINUE, 2)
            )
            .addAction(
                R.drawable.ic_menu_delete,
                "Delete",
                createActionPendingIntent(entity.id, DownloadActionReceiver.ACTION_DELETE, 4)
            )
            .build()

        notificationManager.notify(statusNotificationId(entity.id), notification)
    }

    fun dismissStatusNotification(downloadId: Long) {
        notificationManager.cancel(statusNotificationId(downloadId))
    }

    fun dismissAllNotifications(downloadId: Long) {
        notificationManager.cancel(downloadId.toInt())
        notificationManager.cancel(statusNotificationId(downloadId))
    }

    private fun statusNotificationId(downloadId: Long): Int =
        downloadId.toInt() + STATUS_NOTIFICATION_OFFSET

    private fun createActionPendingIntent(
        downloadId: Long,
        action: String,
        actionCode: Int
    ): PendingIntent {
        val intent = Intent(context, DownloadActionReceiver::class.java).apply {
            this.action = action
            putExtra(DownloadActionReceiver.EXTRA_DOWNLOAD_ID, downloadId)
        }
        val requestCode = (downloadId.toInt() * 10) + actionCode
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun buildPreferenceSummary(entity: DownloadEntity): String {
        return buildList {
            add(if (entity.isWifiOnly) "Wi-Fi Only" else "Any Network")
            if (entity.isPowerSavingEnabled) add("Battery Saver")
        }.joinToString(" • ")
    }

    private fun formatBytes(bytes: Long): String {
        if (bytes <= 0L) return "0 B"
        val kb = bytes / 1024.0
        val mb = kb / 1024.0
        return when {
            mb >= 1.0 -> String.format(Locale.US, "%.2f MB", mb)
            kb >= 1.0 -> String.format(Locale.US, "%.1f KB", kb)
            else -> "$bytes B"
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows progress and controls for file downloads"
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    companion object {
        private const val CHANNEL_ID = "download_manager_channel"
        private const val CHANNEL_NAME = "File Downloads"
        private const val STATUS_NOTIFICATION_OFFSET = 100_000
    }
}