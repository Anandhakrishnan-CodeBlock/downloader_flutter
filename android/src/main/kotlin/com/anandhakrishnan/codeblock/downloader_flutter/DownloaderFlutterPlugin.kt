package com.anandhakrishnan.codeblock.downloader_flutter

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.anandhakrishnan.codeblock.downloader_flutter.database.AppDatabase
import com.anandhakrishnan.codeblock.downloader_flutter.database.repository.DownloadRepository
import com.anandhakrishnan.codeblock.downloader_flutter.database.repository.DownloadRepositoryImpl
import com.anandhakrishnan.codeblock.downloader_flutter.mapper.DownloadEntityMapper
import com.anandhakrishnan.codeblock.downloader_flutter.work_manager.DownloadWorkScheduler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

class DownloaderFlutterPlugin :
    FlutterPlugin,
    MethodCallHandler,
    EventChannel.StreamHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var appContext: Context
    private lateinit var repository: DownloadRepository
    private lateinit var scheduler: DownloadWorkScheduler

    private val pluginScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var downloadsStreamJob: Job? = null

    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermissionResult: Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        val dao = AppDatabase.getInstance(appContext).downloadDao()
        repository = DownloadRepositoryImpl(dao)
        scheduler = DownloadWorkScheduler(appContext, repository)

        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "requestNotificationPermission" -> handleNotificationPermission(result)

            "downloadSingleFile" -> {
                val url = call.argument<String>("url")
                val fileName = call.argument<String>("fileName")
                if (url.isNullOrBlank() || fileName.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENTS", "url and fileName are required", null)
                    return
                }

                val isImmediate = call.argument<Boolean>("isImmediate") ?: true
                val isWifiOnly = call.argument<Boolean>("isWifiOnly") ?: false
                val isPowerSavingEnabled = call.argument<Boolean>("isPowerSavingEnabled") ?: false
                val isOneByOne = call.argument<Boolean>("isOneByOne") ?: false
                val showToast = call.argument<Boolean>("showToastAndroid") ?: false
                val maxRetry = call.argument<Int>("maxRetry") ?: 3

                pluginScope.launch {
                    scheduler.enqueueDownload(
                        url = url,
                        fileName = fileName,
                        isImmediate = isImmediate,
                        isWifiOnly = isWifiOnly,
                        isPowerSavingEnabled = isPowerSavingEnabled,
                        isOneByOne = isOneByOne,
                        showToast = showToast,
                        maxRetry = maxRetry
                    ).onSuccess { id ->
                        result.success(id)
                    }.onFailure { error ->
                        result.error("ENQUEUE_ERROR", error.message, null)
                    }
                }
            }

            "downloadMultipleFiles" -> {
                val rawItems = call.argument<List>>("items")
                if (rawItems.isNullOrEmpty()) {
                    result.error("INVALID_ARGUMENTS", "items list cannot be empty", null)
                    return
                }

                val items = rawItems.mapNotNull { map ->
                    val url = map["url"] as? String
                    val fileName = map["fileName"] as? String
                    if (!url.isNullOrBlank() && !fileName.isNullOrBlank()) url to fileName else null
                }

                if (items.isEmpty()) {
                    result.error("INVALID_ARGUMENTS", "No valid url/fileName pairs found", null)
                    return
                }

                val isImmediate = call.argument<Boolean>("isImmediate") ?: true
                val isWifiOnly = call.argument<Boolean>("isWifiOnly") ?: false
                val isPowerSavingEnabled = call.argument<Boolean>("isPowerSavingEnabled") ?: false
                val isOneByOne = call.argument<Boolean>("isOneByOne") ?: false
                val showToast = call.argument<Boolean>("showToastAndroid") ?: false
                val maxRetry = call.argument<Int>("maxRetry") ?: 3

                pluginScope.launch {
                    try {
                        scheduler.enqueueMultipleDownloads(
                            items = items,
                            isImmediate = isImmediate,
                            isWifiOnly = isWifiOnly,
                            isPowerSavingEnabled = isPowerSavingEnabled,
                            isOneByOne = isOneByOne,
                            showToast = showToast,
                            maxRetry = maxRetry
                        )
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("BATCH_ENQUEUE_ERROR", e.message, null)
                    }
                }
            }

            "pauseDownload" -> {
                val id = call.argument<Number>("id")?.toLong()
                if (id == null) {
                    result.error("INVALID_ARGUMENTS", "id is required", null)
                    return
                }
                val showToast = call.argument<Boolean>("showToastAndroid")
                pluginScope.launch {
                    scheduler.pauseDownload(id, showToast)
                    result.success(null)
                }
            }

            "resumeDownload" -> {
                val id = call.argument<Number>("id")?.toLong()
                if (id == null) {
                    result.error("INVALID_ARGUMENTS", "id is required", null)
                    return
                }
                val showToast = call.argument<Boolean>("showToastAndroid")
                pluginScope.launch {
                    scheduler.resumeDownload(id, showToast)
                    result.success(null)
                }
            }

            "cancelDownload" -> {
                val id = call.argument<Number>("id")?.toLong()
                if (id == null) {
                    result.error("INVALID_ARGUMENTS", "id is required", null)
                    return
                }
                val showToast = call.argument<Boolean>("showToastAndroid")
                pluginScope.launch {
                    scheduler.cancelDownload(id, showToast)
                    result.success(null)
                }
            }

            "deleteDownload" -> {
                val id = call.argument<Number>("id")?.toLong()
                if (id == null) {
                    result.error("INVALID_ARGUMENTS", "id is required", null)
                    return
                }
                val showToast = call.argument<Boolean>("showToastAndroid")
                pluginScope.launch {
                    scheduler.deleteDownload(id, showToast)
                    result.success(null)
                }
            }

            "getAllDownloads" -> {
                pluginScope.launch {
                    try {
                        val list = repository.getAllDownloads().first()
                        result.success(list.map { DownloadEntityMapper.toMap(it) })
                    } catch (e: Exception) {
                        result.error("FETCH_ERROR", e.message, null)
                    }
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun handleNotificationPermission(result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }

        val granted = ContextCompat.checkSelfPermission(
            appContext,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED

        if (granted) {
            result.success(true)
            return
        }

        val activity = activityBinding?.activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "Plugin is not attached to an Activity", null)
            return
        }

        if (pendingPermissionResult != null) {
            result.error("PERMISSION_IN_PROGRESS", "Permission request already active", null)
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_CODE_NOTIFICATIONS
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == REQUEST_CODE_NOTIFICATIONS) {
            val isGranted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(isGranted)
            pendingPermissionResult = null
            return true
        }
        return false
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        downloadsStreamJob?.cancel()
        downloadsStreamJob = pluginScope.launch {
            repository.getAllDownloads()
                .catch { error ->
                    events?.error("STREAM_ERROR", error.message, null)
                }
                .collect { entities ->
                    events?.success(entities.map { DownloadEntityMapper.toMap(it) })
                }
        }
    }

    override fun onCancel(arguments: Any?) {
        downloadsStreamJob?.cancel()
        downloadsStreamJob = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        downloadsStreamJob?.cancel()
        pluginScope.cancel()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    companion object {
        private const val METHOD_CHANNEL_NAME =
            "com.anandhakrishnan.codeblock.downloader_flutter/methods"
        private const val EVENT_CHANNEL_NAME =
            "com.anandhakrishnan.codeblock.downloader_flutter/events"
        private const val REQUEST_CODE_NOTIFICATIONS = 9042
    }
}