import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'downloader_flutter_method_channel.dart';
import 'src/models/download_preferences.dart';
import 'src/models/download_task.dart';

abstract class DownloaderFlutterPlatform extends PlatformInterface {
  DownloaderFlutterPlatform() : super(token: _token);

  static final Object _token = Object();
  static DownloaderFlutterPlatform _instance = MethodChannelDownloaderFlutter();

  static DownloaderFlutterPlatform get instance => _instance;

  static set instance(DownloaderFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> requestNotificationPermission() {
    throw UnimplementedError('requestNotificationPermission() has not been implemented.');
  }

  Future<int> downloadSingleFile({
    required String url,
    required String fileName,
    DownloadPreferences preferences = const DownloadPreferences(),
  }) {
    throw UnimplementedError('downloadSingleFile() has not been implemented.');
  }

  Future<void> downloadMultipleFiles({
    required List<DownloadRequestItem> items,
    DownloadPreferences preferences = const DownloadPreferences(),
  }) {
    throw UnimplementedError('downloadMultipleFiles() has not been implemented.');
  }

  Future<void> pauseDownload(int id, {bool? showToastAndroid}) {
    throw UnimplementedError('pauseDownload() has not been implemented.');
  }

  Future<void> resumeDownload(int id, {bool? showToastAndroid}) {
    throw UnimplementedError('resumeDownload() has not been implemented.');
  }

  Future<void> cancelDownload(int id, {bool? showToastAndroid}) {
    throw UnimplementedError('cancelDownload() has not been implemented.');
  }

  Future<void> deleteDownload(int id, {bool? showToastAndroid}) {
    throw UnimplementedError('deleteDownload() has not been implemented.');
  }

  Future<List<DownloadTask>> getAllDownloads() {
    throw UnimplementedError('getAllDownloads() has not been implemented.');
  }

  Stream<List<DownloadTask>> watchDownloads() {
    throw UnimplementedError('watchDownloads() has not been implemented.');
  }
}