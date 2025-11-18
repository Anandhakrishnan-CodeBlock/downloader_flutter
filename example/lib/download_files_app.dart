import 'package:downloader_flutter/downloader_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';

class DownloadFilesApp extends State<MyApp> {
  final _downloadManagerFlutterPlugin = DownloaderFlutter();
  String _fdmStatus = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  downloadSingleFile();
                },
                child: Text("Download Single File"),
              ),
              ElevatedButton(
                onPressed: () {
                  downloadMultipleFile();
                },
                child: Text("Download Multiple File"),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text('Flutter Download Manager Status:'),
                    SizedBox(height: 10,),
                    Text(_fdmStatus),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void downloadSingleFile() async {
    try {
      _fdmStatus = await _downloadManagerFlutterPlugin.downloadSingleFile(
            url: 'https://picsum.photos/id/237/200/300',
            fileName: "sample.jpg",
            saveToPhoto: true,
            showToastAndroid: false,
            response: (data) {
              _fdmStatus = "Response In App: $data";
            },
          ) ?? 'Download Manager Not Connected';

      _downloadManagerFlutterPlugin.downloadProgress().listen((event) {
        handleDownloadEvent(event);
      });

    } on PlatformException {
      _fdmStatus = 'Failed to get platform version.';
    }
    setState(() {});
  }

  void downloadMultipleFile() async {
    try {
      _fdmStatus = await _downloadManagerFlutterPlugin.downloadMultipleFile(
        urls: [
          'https://picsum.photos/id/237/200/300',
          'https://picsum.photos/id/237/200/300',
          'https://picsum.photos/id/237/200/300',
        ],
        fileNames: [
          'image1.jpg',
          'image2.jpg',
          'image3.jpg',
        ],
        saveToPhoto: true,
        showToastAndroid: true,
        response: (data) {
          _fdmStatus = "Response In App: $data";
        },
      ) ?? 'Download Manager Not Connected';

      _downloadManagerFlutterPlugin.downloadProgress().listen((event) {
        handleDownloadEvent(event);
      });

    } on PlatformException {
      _fdmStatus = 'Failed to get platform version.';
    }
    setState(() {});
  }

  void handleDownloadEvent(Map<String, dynamic> event) {
    final status = event["status"] as String?;
    if (status == null) {
      debugPrint("⚠️ Unknown event: $event");
      return;
    }

    final fileName = event["fileName"] as String? ?? "unknown";

    switch (status) {
      case "started":
        debugPrint("🚀 Started $fileName");
        break;

      case "progress":
        final progress = event["progress"] as int? ?? 0;
        debugPrint("📊 Progress $fileName: $progress%");
        break;

      case "success":
        debugPrint("✅ Completed $fileName");
        break;

      case "saved":
        debugPrint("📷 Saved to photo $fileName");
        break;

      case "failed":
        debugPrint("❌ Failed $fileName");
        break;

      case "completed":
        debugPrint("🎉 Download completed $fileName");
        break;

      case "error":
        final message = event["message"] as String? ?? "Unknown error";
        debugPrint("⚠️ Error: $message");
        break;

      default:
        debugPrint("❓ Unknown status: $status");
    }
  }
}
