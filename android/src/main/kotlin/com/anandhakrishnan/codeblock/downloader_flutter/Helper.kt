package com.anandhakrishnan.codeblock.downloader_flutter

object DownloadProgress {

    fun statusStarted(fileName: String): Map<String, Any> {
        return mapOf(
            "status" to "started",
            "fileName" to fileName
        )
    }

    fun statusProgress(fileName: String, progress: Int): Map<String, Any> {
        return mapOf(
            "status" to "progress",
            "fileName" to fileName,
            "progress" to progress
        )
    }

    fun statusCompleted(fileName: String): Map<String, Any> {
        return mapOf(
            "status" to "completed",
            "fileName" to fileName
        )
    }

    fun statusSaved(fileName: String): Map<String, Any> {
        return mapOf(
            "status" to "saved",
            "fileName" to fileName
        )
    }

    fun statusSuccess(fileName: String): Map<String, Any> {
        return mapOf(
            "status" to "success",
            "fileName" to fileName
        )
    }

    fun statusFailed(fileName: String, message: String): Map<String, Any> {
        return mapOf(
            "status" to "failed",
            "fileName" to fileName,
            "message" to message
        )
    }

    fun statusError(fileName: String, message: String): Map<String, Any> {
        return mapOf(
            "status" to "error",
            "fileName" to fileName,
            "message" to message
        )
    }
}
