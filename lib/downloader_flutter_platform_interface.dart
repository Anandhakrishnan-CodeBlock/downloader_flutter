import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'downloader_flutter_method_channel.dart';

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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
