import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'downloader_flutter_platform_interface.dart';
import 'src/models/download_preferences.dart';
import 'src/models/download_task.dart';

class MethodChannelDownloaderFlutter extends DownloaderFlutterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel(
    'com.anandhakrishnan.codeblock.downloader_flutter/methods',
  );

  @visibleForTesting
  final eventChannel = const EventChannel(
    'com.anandhakrishnan.codeblock.downloader_flutter/events',
  );

  Stream<List<DownloadTask>>? _downloadsStream;

  @override
  Future<bool> requestNotificationPermission() async {
    final granted = await methodChannel.invokeMethod<bool>('requestNotificationPermission');
    return granted ?? false;
  }

  @override
  Future<int> downloadSingleFile({
    required String url,
    required String fileName,
    DownloadPreferences preferences = const DownloadPreferences(),
  }) async {
    final id = await methodChannel.invokeMethod<int>('downloadSingleFile', {
      'url': url,
      'fileName': fileName,
      ...preferences.toMap(),
    });
    return id ?? -1;
  }

  @override
  Future<void> downloadMultipleFiles({
    required List<DownloadRequestItem> items,
    DownloadPreferences preferences = const DownloadPreferences(),
  }) async {
    await methodChannel.invokeMethod<void>('downloadMultipleFiles', {
      'items': items.map((e) => e.toMap()).toList(),
      ...preferences.toMap(),
    });
  }

  @override
  Future<void> pauseDownload(int id, {bool? showToastAndroid}) async {
    await methodChannel.invokeMethod<void>('pauseDownload', {
      'id': id,
      if (showToastAndroid != null) 'showToastAndroid': showToastAndroid,
    });
  }

  @override
  Future<void> resumeDownload(int id, {bool? showToastAndroid}) async {
    await methodChannel.invokeMethod<void>('resumeDownload', {
      'id': id,
      if (showToastAndroid != null) 'showToastAndroid': showToastAndroid,
    });
  }

  @override
  Future<void> cancelDownload(int id, {bool? showToastAndroid}) async {
    await methodChannel.invokeMethod<void>('cancelDownload', {
      'id': id,
      if (showToastAndroid != null) 'showToastAndroid': showToastAndroid,
    });
  }

  @override
  Future<void> deleteDownload(int id, {bool? showToastAndroid}) async {
    await methodChannel.invokeMethod<void>('deleteDownload', {
      'id': id,
      if (showToastAndroid != null) 'showToastAndroid': showToastAndroid,
    });
  }

  @override
  Future<List<DownloadTask>> getAllDownloads() async {
    final rawList = await methodChannel.invokeListMethod<dynamic>('getAllDownloads');
    if (rawList == null) return const [];
    return rawList
        .map((item) => DownloadTask.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Stream<List<DownloadTask>> watchDownloads() {
    _downloadsStream ??= eventChannel.receiveBroadcastStream().map((event) {
      final rawList = event as List<dynamic>;
      return rawList
          .map((item) => DownloadTask.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    });
    return _downloadsStream!;
  }
}