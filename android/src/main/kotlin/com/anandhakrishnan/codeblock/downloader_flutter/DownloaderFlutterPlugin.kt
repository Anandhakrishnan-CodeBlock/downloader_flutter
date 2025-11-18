package com.anandhakrishnan.codeblock.downloader_flutter

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** DownloaderFlutterPlugin */
class DownloaderFlutterPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var singleFileDownloadChannel: MethodChannel
    private lateinit var multipleFileDownloadChannel: MethodChannel
    private lateinit var downloadProgressEventChannel: EventChannel
    val downloadSingleFileMethodChannel = "download_single_file_method_channel"
    val downloadSingleFileMethod = "downloadSingleFileMethod"
    val downloadMultipleFileMethodChannel = "download_multiple_file_method_channel"
    val downloadMultipleFileMethod = "downloadMultipleFileMethod"
    val downloadProgressEvent = "download_progress_events"
    private lateinit var context: Context
    private var eventSink: EventChannel.EventSink? = null


    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        singleFileDownloadChannel = MethodChannel(flutterPluginBinding.binaryMessenger, downloadSingleFileMethodChannel)
        singleFileDownloadChannel.setMethodCallHandler(this)
        multipleFileDownloadChannel = MethodChannel(flutterPluginBinding.binaryMessenger, downloadMultipleFileMethodChannel)
        multipleFileDownloadChannel.setMethodCallHandler(this)
        downloadProgressEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, downloadProgressEvent)
        downloadProgressEventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {

            downloadSingleFileMethod -> {
                val url = call.argument<String>("url")
                val fileName = call.argument<String>("file_name")
                val showToast = call.argument<Boolean>("show_toast") ?: false

                if (url.isNullOrEmpty()) {
                    result.error("INVALID_ARGUMENTS", "Missing 'url'", null)
                    return
                }

                if (fileName.isNullOrEmpty()){
                    result.error("INVALID_ARGUMENTS", "Missing 'file name", null)
                    return
                }

                // Call our new downloader class
                DownloadManagerFlutter.downloadSingleFile(
                    context,
                    url = url,
                    fileName = fileName,
                    showToast = showToast,
                    completion = { completion ->
                        result.success(completion)
                    },
                    progressCallback = { progressMap ->
                        eventSink?.success(progressMap)
                    })

            }

            downloadMultipleFileMethod -> {

                val urls = call.argument<List<String>>("urls")
                val fileNames = call.argument<List<String>>("file_names")
                val showToast = call.argument<Boolean>("show_toast") ?: false

                if (urls.isNullOrEmpty() || fileNames.isNullOrEmpty() || urls.size != fileNames.size) {
                    result.error("INVALID_ARGUMENTS", "URLs or file names missing/mismatched", null)
                    return
                }

                // Call our new downloader class
                DownloadManagerFlutter.downloadMultipleFiles(
                    context,
                    urls = urls,
                    fileNames = fileNames,
                    showToast = showToast,
                    completion = { completion ->
                        result.success(completion)
                    },
                    progressCallback = { progressMap ->
                        eventSink?.success(progressMap)
                    }
                )
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        singleFileDownloadChannel.setMethodCallHandler(null)
        multipleFileDownloadChannel.setMethodCallHandler(null)
        downloadProgressEventChannel.setStreamHandler(null)
    }
}
