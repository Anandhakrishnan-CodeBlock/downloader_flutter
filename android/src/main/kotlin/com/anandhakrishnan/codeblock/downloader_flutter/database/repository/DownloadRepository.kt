package com.anandhakrishnan.codeblock.downloader_flutter.database.repository

import com.anandhakrishnan.codeblock.downloader_flutter_android.database.entity.DownloadEntity
import kotlinx.coroutines.flow.Flow

interface DownloadRepository {

    fun getAllDownloads(): Flow<List<DownloadEntity>>

    suspend fun getDownloadById(id: Long): Result<DownloadEntity?>

    suspend fun insertDownload(download: DownloadEntity): Result<Long>

    suspend fun updateDownload(download: DownloadEntity): Result<Int>

    suspend fun deleteDownload(download: DownloadEntity): Result<Int>

    suspend fun updateProgress(
        id: Long,
        percentage: Float,
        downloadedBytes: Long,
        totalBytes: Long
    ): Result<Int>

    suspend fun countActiveSequentialDownloads(): Result<Int>

    suspend fun getNextSequentialDownload(): Result<DownloadEntity?>
}