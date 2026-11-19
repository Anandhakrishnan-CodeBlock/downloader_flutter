package com.anandhakrishnan.codeblock.downloader_flutter.storage

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.OutputStream

class StorageHelper(private val context: Context) {

    fun createTargetUri(fileName: String, mimeType: String): Uri {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            context.contentResolver.insert(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                values
            ) ?: throw IllegalStateException("Failed to create MediaStore entry")
        } else {
            @Suppress("DEPRECATION")
            val downloadsDir =
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) downloadsDir.mkdirs()
            Uri.fromFile(File(downloadsDir, fileName))
        }
    }

    fun openOutputStream(uri: Uri, isResuming: Boolean): OutputStream {
        val mode = if (isResuming) "wa" else "w"
        return context.contentResolver.openOutputStream(uri, mode)
            ?: throw IllegalStateException("Unable to open output stream for $uri")
    }

    fun finalizeFile(uri: Uri) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && uri.scheme == "content") {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.IS_PENDING, 0)
            }
            context.contentResolver.update(uri, values, null, null)
        }
    }

    fun deleteFile(uri: Uri): Boolean {
        return runCatching {
            if (uri.scheme == "content") {
                context.contentResolver.delete(uri, null, null) > 0
            } else {
                uri.path?.let { File(it).delete() } ?: false
            }
        }.getOrDefault(false)
    }
}