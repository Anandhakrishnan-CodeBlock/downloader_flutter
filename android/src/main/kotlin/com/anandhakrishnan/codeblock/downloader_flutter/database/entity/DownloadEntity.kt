package com.anandhakrishnan.codeblock.downloader_flutter.database.entity

import androidx.room3.ColumnInfo
import androidx.room3.Entity
import androidx.room3.PrimaryKey
import java.util.Date

@Entity(tableName = "downloads")
data class DownloadEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,

    @ColumnInfo(name = "work_id")
    val workId: String? = null,

    @ColumnInfo(name = "file_name")
    val fileName: String,

    @ColumnInfo(name = "url")
    val url: String,

    @ColumnInfo(name = "status")
    val status: DownloadStatus = DownloadStatus.QUEUED,

    @ColumnInfo(name = "percentage")
    val percentage: Float = 0f,

    @ColumnInfo(name = "downloaded_bytes")
    val downloadedBytes: Long = 0L,

    @ColumnInfo(name = "total_bytes")
    val totalBytes: Long = 0L,

    @ColumnInfo(name = "file_uri")
    val fileUri: String? = null,

    @ColumnInfo(name = "mime_type")
    val mimeType: String? = null,

    @ColumnInfo(name = "max_retry")
    val maxRetry: Int = 3,

    @ColumnInfo(name = "retried")
    val retried: Int = 0,

    @ColumnInfo(name = "is_immediate")
    val isImmediate: Boolean = true,

    @ColumnInfo(name = "is_wifi_only")
    val isWifiOnly: Boolean = false,

    @ColumnInfo(name = "is_power_saving_enabled")
    val isPowerSavingEnabled: Boolean = false,

    @ColumnInfo(name = "is_one_by_one")
    val isOneByOne: Boolean = false,

    @ColumnInfo(name = "show_toast")
    val showToast: Boolean = false,

    @ColumnInfo(name = "error_message")
    val errorMessage: String? = null,

    @ColumnInfo(name = "created_at")
    val createdAt: Date = Date()
)