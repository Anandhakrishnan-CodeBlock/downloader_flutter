package com.anandhakrishnan.codeblock.downloader_flutter.mapper

import com.anandhakrishnan.codeblock.downloader_flutter.database.entity.DownloadEntity

object DownloadEntityMapper {

    fun toMap(entity: DownloadEntity): Map<String, Any?> = mapOf(
        "id" to entity.id,
        "workId" to entity.workId,
        "fileName" to entity.fileName,
        "url" to entity.url,
        "status" to entity.status.name,
        "percentage" to entity.percentage.toDouble(),
        "downloadedBytes" to entity.downloadedBytes,
        "totalBytes" to entity.totalBytes,
        "fileUri" to entity.fileUri,
        "mimeType" to entity.mimeType,
        "maxRetry" to entity.maxRetry,
        "retried" to entity.retried,
        "isImmediate" to entity.isImmediate,
        "isWifiOnly" to entity.isWifiOnly,
        "isPowerSavingEnabled" to entity.isPowerSavingEnabled,
        "isOneByOne" to entity.isOneByOne,
        "showToast" to entity.showToast,
        "errorMessage" to entity.errorMessage,
        "createdAt" to entity.createdAt.time
    )
}