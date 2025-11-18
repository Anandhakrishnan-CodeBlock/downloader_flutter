import 'package:flutter_test/flutter_test.dart';
import 'package:downloader_flutter/downloader_flutter.dart';
import 'package:downloader_flutter/downloader_flutter_platform_interface.dart';
import 'package:downloader_flutter/downloader_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDownloaderFlutterPlatform
    with MockPlatformInterfaceMixin
    implements DownloaderFlutterPlatform {

  @override
  Future<String?> downloadSingleFile({
    required String? url,
    required String fileName,
    required Function response,
    bool? saveToPhoto,
    bool? showToastAndroid
  }) => Future.value("Download Response");

  @override
  Future<String?> downloadMultipleFile({
    required List<String?> urls,
    required List<String> fileNames,
    required Function response,
    bool? saveToPhoto,
    bool? showToastAndroid}) {
    return Future.value("Download Response");
  }

  @override
  Stream<Map<String, dynamic>> downloadProgress() {
    return Stream.value({});
  }
}

void main() {
  final DownloaderFlutterPlatform initialPlatform = DownloaderFlutterPlatform.instance;
  DownloaderFlutter downloaderFlutterPlugin = DownloaderFlutter();
  MockDownloaderFlutterPlatform fakePlatform = MockDownloaderFlutterPlatform();
  DownloaderFlutterPlatform.instance = fakePlatform;

  test('$MethodChannelDownloaderFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDownloaderFlutter>());
  });

  test('downloadSingleFile', () async {
    expect(await downloaderFlutterPlugin.downloadSingleFile(
      url: "https://picsum.photos/id/237/200/300",
      fileName: 'Sample',
      response: (data) { },
    ), "Download Response");
  });
}
