package com.anandhakrishnan.codeblock.downloader_flutter.database.dao

import androidx.room3.Dao
import androidx.room3.Delete
import androidx.room3.Insert
import androidx.room3.OnConflictStrategy
import androidx.room3.Query
import androidx.room3.Update
import com.anandhakrishnan.codeblock.downloader_flutter_android.database.entity.DownloadEntity
import com.anandhakrishnan.codeblock.downloader_flutter_android.database.entity.DownloadStatus
import kotlinx.coroutines.flow.Flow

@Dao
interface DownloadDao {

    @Query("SELECT * FROM downloads ORDER BY created_at DESC")
    fun getAllDownloads(): Flow<List<DownloadEntity>>

    @Query("SELECT * FROM downloads WHERE id = :id")
    suspend fun getDownloadById(id: Long): DownloadEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertDownload(download: DownloadEntity): Long

    @Update
    suspend fun updateDownload(download: DownloadEntity): Int

    @Delete
    suspend fun deleteDownload(download: DownloadEntity): Int

    @Query("UPDATE downloads SET percentage = :percentage, downloaded_bytes = :downloadedBytes, total_bytes = :totalBytes WHERE id = :id")
    suspend fun updateProgress(id: Long, percentage: Float, downloadedBytes: Long, totalBytes: Long): Int

    @Query("SELECT COUNT(*) FROM downloads WHERE is_one_by_one = 1 AND status = :status")
    suspend fun countSequentialDownloadsByStatus(
        status: DownloadStatus = DownloadStatus.RUNNING
    ): Int

    @Query("SELECT * FROM downloads WHERE is_one_by_one = 1 AND status = :status ORDER BY id ASC LIMIT 1")
    suspend fun getNextSequentialDownload(
        status: DownloadStatus = DownloadStatus.QUEUED
    ): DownloadEntity?
}
