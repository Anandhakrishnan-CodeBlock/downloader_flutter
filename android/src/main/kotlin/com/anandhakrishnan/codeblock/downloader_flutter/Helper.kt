package com.anandhakrishnan.codeblock.downloader_flutter

object DownloadProgress {

    fun statusStarted(fileName: String, filePath: String? = null): Map<String, Any?> {
        return mapOf(
            "status" to "started",
            "fileName" to fileName,
            "filePath" to filePath
        )
    }

    fun statusProgress(fileName: String, progress: Int, filePath: String? = null): Map<String, Any?> {
        return mapOf(
            "status" to "progress",
            "fileName" to fileName,
            "progress" to progress,
            "filePath" to filePath
        )
    }

    fun statusCompleted(fileName: String, filePath: String? = null): Map<String, Any?> {
        return mapOf(
            "status" to "completed",
            "fileName" to fileName,
            "filePath" to filePath
        )
    }

    fun statusSaved(fileName: String, filePath: String? = null): Map<String, Any?> {
        return mapOf(
            "status" to "saved",
            "fileName" to fileName,
            "filePath" to filePath
        )
    }

    fun statusSuccess(fileName: String, filePath: String? = null): Map<String, Any?> {
        return mapOf(
            "status" to "success",
            "fileName" to fileName,
            "filePath" to filePath
        )
    }

    fun statusFailed(fileName: String, message: String, filePath: String? = null): Map<String, Any?> {
        return mapOf(
            "status" to "failed",
            "fileName" to fileName,
            "message" to message,
            "filePath" to filePath
        )
    }

    fun statusError(fileName: String, message: String, filePath: String? = null): Map<String, Any?> {
        return mapOf(
            "status" to "error",
            "fileName" to fileName,
            "message" to message,
            "filePath" to filePath
        )
    }
}
