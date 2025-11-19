import 'package:downloader_flutter/downloader_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => DownloadFilesApp();
}

class DownloadFilesApp extends State<MyApp> {
  final _downloadManagerFlutterPlugin = DownloaderFlutter();
  String _fdmStatus = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Downloader Flutter')),
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
        url: 'https://images.pexels.com/photos/10725897/pexels-photo-10725897.jpeg',
        fileName: "image.jpeg",
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
          'https://images.pexels.com/photos/177598/pexels-photo-177598.jpeg',
          'https://images.pexels.com/photos/577585/pexels-photo-577585.jpeg',
          'https://images.pexels.com/photos/1181244/pexels-photo-1181244.jpeg',
          'https://images.pexels.com/photos/4816921/pexels-photo-4816921.jpeg',
          'https://images.pexels.com/photos/248515/pexels-photo-248515.png',
        ],
        fileNames: [
          'image1.jpg',
          'image2.jpg',
          'image3.jpg',
          'image4.jpg',
          'image5.png',
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