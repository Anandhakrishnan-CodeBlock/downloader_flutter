import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'downloader_flutter_method_channel.dart';

/// DownloaderFlutterPlatform
/// DownloaderFlutterPlatform is a abstract class
/// Hold the declaration methods
/// - downloadSingleFile()
/// - downloadMultipleFile()
/// - downloadProgress()

abstract class DownloaderFlutterPlatform extends PlatformInterface {
  /// Constructs a DownloaderFlutterPlatform.
  DownloaderFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static DownloaderFlutterPlatform _instance = MethodChannelDownloaderFlutter();

  /// The default instance of [DownloaderFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelDownloaderFlutter].
  static DownloaderFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DownloaderFlutterPlatform] when
  /// they register themselves.
  static set instance(DownloaderFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> downloadSingleFile({
    required String? url,
    required String fileName,
    required Function response,
    bool? saveToPhoto = false,
    bool? showToastAndroid = false}) async {
    throw UnimplementedError('downloadSingleFile() has not been implemented.');
  }

  Future<String?> downloadMultipleFile({
    required List<String?> urls,
    required List<String> fileNames,
    required Function response,
    bool? saveToPhoto = false,
    bool? showToastAndroid = false}) async {
    throw UnimplementedError('downloadMultipleFile() has not been implemented.');
  }

  Stream<Map<String, dynamic>> downloadProgress() async* {
    throw UnimplementedError('downloadProgress() has not been implemented.');
  }
}
