import 'package:flutter_test/flutter_test.dart';
import 'package:downloader_flutter/downloader_flutter.dart';
import 'package:downloader_flutter/downloader_flutter_platform_interface.dart';
import 'package:downloader_flutter/downloader_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDownloaderFlutterPlatform
    with MockPlatformInterfaceMixin
    implements DownloaderFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DownloaderFlutterPlatform initialPlatform = DownloaderFlutterPlatform.instance;

  test('$MethodChannelDownloaderFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDownloaderFlutter>());
  });

  test('getPlatformVersion', () async {
    DownloaderFlutter downloaderFlutterPlugin = DownloaderFlutter();
    MockDownloaderFlutterPlatform fakePlatform = MockDownloaderFlutterPlatform();
    DownloaderFlutterPlatform.instance = fakePlatform;

    expect(await downloaderFlutterPlugin.getPlatformVersion(), '42');
  });
}
