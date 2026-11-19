package com.anandhakrishnan.codeblock.downloader_flutter.notification

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.anandhakrishnan.codeblock.downloader_flutter_android.database.DownloaderDatabase
import com.anandhakrishnan.codeblock.downloader_flutter_android.database.repository.DownloadRepositoryImpl
import com.anandhakrishnan.codeblock.downloader_flutter_android.work_manager.DownloadWorkScheduler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class DownloadActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val downloadId = intent.getLongExtra(EXTRA_DOWNLOAD_ID, -1L)
        if (downloadId == -1L) return

        val action = intent.action ?: return
        val pendingResult = goAsync()
        val appContext = context.applicationContext

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val dao = DownloaderDatabase.getInstance(appContext).downloadDao()
                val repository = DownloadRepositoryImpl(dao)
                val scheduler = DownloadWorkScheduler(appContext, repository)

                when (action) {
                    ACTION_PAUSE -> scheduler.pauseDownload(downloadId)
                    ACTION_CONTINUE -> scheduler.resumeDownload(downloadId)
                    ACTION_STOP -> scheduler.cancelDownload(downloadId)
                    ACTION_DELETE -> scheduler.deleteDownload(downloadId)
                }
            } finally {
                pendingResult.finish()
            }
        }
    }

    companion object {
        const val EXTRA_DOWNLOAD_ID = "extra_download_id"
        const val ACTION_PAUSE = "com.example.android_download_manager.ACTION_PAUSE"
        const val ACTION_CONTINUE = "com.example.android_download_manager.ACTION_CONTINUE"
        const val ACTION_STOP = "com.example.android_download_manager.ACTION_STOP"
        const val ACTION_DELETE = "com.example.android_download_manager.ACTION_DELETE"
    }
}