import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'downloader_flutter_platform_interface.dart';

/// An implementation of [DownloaderFlutterPlatform] that uses method channels.
class MethodChannelDownloaderFlutter extends DownloaderFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('downloader_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
