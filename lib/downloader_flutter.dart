export 'src/models/download_preferences.dart';
export 'src/models/download_status.dart';
export 'src/models/download_task.dart';

import 'downloader_flutter_platform_interface.dart';
import 'src/models/download_preferences.dart';
import 'src/models/download_task.dart';

class DownloaderFlutter {
  Future<bool> requestNotificationPermission() {
    return DownloaderFlutterPlatform.instance.requestNotificationPermission();
  }

  Future<int> downloadSingleFile({
    required String url,
    required String fileName,
    DownloadPreferences preferences = const DownloadPreferences(),
  }) {
    return DownloaderFlutterPlatform.instance.downloadSingleFile(
      url: url,
      fileName: fileName,
      preferences: preferences,
    );
  }

  Future<void> downloadMultipleFiles({
    required List<DownloadRequestItem> items,
    DownloadPreferences preferences = const DownloadPreferences(),
  }) {
    return DownloaderFlutterPlatform.instance.downloadMultipleFiles(
      items: items,
      preferences: preferences,
    );
  }

  Future<void> pauseDownload(int id, {bool? showToastAndroid}) {
    return DownloaderFlutterPlatform.instance.pauseDownload(
      id,
      showToastAndroid: showToastAndroid,
    );
  }

  Future<void> resumeDownload(int id, {bool? showToastAndroid}) {
    return DownloaderFlutterPlatform.instance.resumeDownload(
      id,
      showToastAndroid: showToastAndroid,
    );
  }

  Future<void> cancelDownload(int id, {bool? showToastAndroid}) {
    return DownloaderFlutterPlatform.instance.cancelDownload(
      id,
      showToastAndroid: showToastAndroid,
    );
  }

  Future<void> deleteDownload(int id, {bool? showToastAndroid}) {
    return DownloaderFlutterPlatform.instance.deleteDownload(
      id,
      showToastAndroid: showToastAndroid,
    );
  }

  Future<List<DownloadTask>> getAllDownloads() {
    return DownloaderFlutterPlatform.instance.getAllDownloads();
  }

  Stream<List<DownloadTask>> watchDownloads() {
    return DownloaderFlutterPlatform.instance.watchDownloads();
  }
}