package com.anandhakrishnan.codeblock.downloader_flutter.database.repository

import com.anandhakrishnan.codeblock.downloader_flutter_android.database.dao.DownloadDao
import com.anandhakrishnan.codeblock.downloader_flutter_android.database.entity.DownloadEntity
import com.anandhakrishnan.codeblock.downloader_flutter_android.database.entity.DownloadStatus
import kotlinx.coroutines.flow.Flow


class DownloadRepositoryImpl(
    private val downloadDao: DownloadDao
) : DownloadRepository {

    override fun getAllDownloads(): Flow<List<DownloadEntity>> =
        downloadDao.getAllDownloads()

    override suspend fun getDownloadById(id: Long): Result<DownloadEntity?> =
        runCatching { downloadDao.getDownloadById(id) }

    override suspend fun insertDownload(download: DownloadEntity): Result<Long> =
        runCatching { downloadDao.insertDownload(download) }

    override suspend fun updateDownload(download: DownloadEntity): Result<Int> =
        runCatching { downloadDao.updateDownload(download) }

    override suspend fun deleteDownload(download: DownloadEntity): Result<Int> =
        runCatching { downloadDao.deleteDownload(download) }

    override suspend fun updateProgress(
        id: Long,
        percentage: Float,
        downloadedBytes: Long,
        totalBytes: Long
    ): Result<Int> =
        runCatching {
            downloadDao.updateProgress(id, percentage, downloadedBytes, totalBytes)
        }

    override suspend fun countActiveSequentialDownloads(): Result<Int> =
        runCatching { downloadDao.countSequentialDownloadsByStatus(DownloadStatus.RUNNING) }

    override suspend fun getNextSequentialDownload(): Result<DownloadEntity?> =
        runCatching { downloadDao.getNextSequentialDownload(DownloadStatus.QUEUED) }
}