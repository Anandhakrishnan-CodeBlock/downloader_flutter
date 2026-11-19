package com.anandhakrishnan.codeblock.downloader_flutter.database.entity

enum class DownloadStatus {
    QUEUED,
    RUNNING,
    PAUSED,
    COMPLETED,
    FAILED,
    CANCELLED
}