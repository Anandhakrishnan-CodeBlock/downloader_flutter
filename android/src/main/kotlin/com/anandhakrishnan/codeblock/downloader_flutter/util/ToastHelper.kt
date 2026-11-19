package com.anandhakrishnan.codeblock.downloader_flutter.util

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.widget.Toast

class ToastHelper(context: Context) {

    private val appContext = context.applicationContext
    private val mainHandler = Handler(Looper.getMainLooper())

    fun show(enabled: Boolean, message: String, isLong: Boolean = false) {
        if (!enabled) return
        mainHandler.post {
            val duration = if (isLong) Toast.LENGTH_LONG else Toast.LENGTH_SHORT
            Toast.makeText(appContext, message, duration).show()
        }
    }
}