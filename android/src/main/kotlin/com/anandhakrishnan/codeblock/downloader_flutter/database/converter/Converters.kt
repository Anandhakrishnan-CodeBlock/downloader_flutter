package com.anandhakrishnan.codeblock.downloader_flutter.database.converter

import androidx.room3.ColumnTypeConverter
import com.anandhakrishnan.codeblock.downloader_flutter_android.database.entity.DownloadStatus
import java.util.Date

class Converters {

    // Date Converters
    @ColumnTypeConverter
    fun fromTimestamp(value: Long?): Date? {
        return value?.let { Date(it) }
    }

    @ColumnTypeConverter
    fun dateToTimestamp(date: Date?): Long? {
        return date?.time
    }

    // Enum Converters
    @ColumnTypeConverter
    fun fromDownloadStatus(status: DownloadStatus): String {
        return status.name
    }

    @ColumnTypeConverter
    fun toDownloadStatus(name: String): DownloadStatus {
        return DownloadStatus.valueOf(name)
    }
}
