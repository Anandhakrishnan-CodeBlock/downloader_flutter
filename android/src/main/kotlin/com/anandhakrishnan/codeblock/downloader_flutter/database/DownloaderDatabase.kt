package com.anandhakrishnan.codeblock.downloader_flutter.database

import android.content.Context
import androidx.room3.ColumnTypeConverters
import androidx.room3.Database
import androidx.room3.Room
import androidx.room3.RoomDatabase
import androidx.sqlite.driver.bundled.BundledSQLiteDriver
import com.anandhakrishnan.codeblock.downloader_flutter_android.database.converter.Converters
import com.anandhakrishnan.codeblock.downloader_flutter_android.database.dao.DownloadDao
import com.anandhakrishnan.codeblock.downloader_flutter_android.database.entity.DownloadEntity

@Database(
    entities = [DownloadEntity::class],
    version = 1,
    exportSchema = true
)
@ColumnTypeConverters(Converters::class)
abstract class DownloaderDatabase : RoomDatabase() {

    abstract fun downloadDao(): DownloadDao

    companion object {
        @Volatile
        private var INSTANCE: DownloaderDatabase? = null

        fun getInstance(context: Context): DownloaderDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    DownloaderDatabase::class.java,
                    "downloader_db"
                )
                    .setDriver(BundledSQLiteDriver())
                    .setJournalMode(JournalMode.WRITE_AHEAD_LOGGING)
                    .fallbackToDestructiveMigration(dropAllTables = true)
                    .build()

                INSTANCE = instance
                instance
            }
        }
    }
}
