import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:downloader_flutter/downloader_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelDownloaderFlutter platform = MethodChannelDownloaderFlutter();
  const downloadSingleFileMethodChannel = MethodChannel('download_single_file_method_channel',);
  const downloadSingleFileMethod = 'downloadSingleFileMethod';

  void setupDownloadSingleFileMock({
    required String? expectedUrl,
    required String expectedFileName,
    bool expectedSaveToPhoto = false,
    bool error = false,
    dynamic response = 'Download started successfully',
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(downloadSingleFileMethodChannel, (
        MethodCall call,
        ) async {
      expect(call.method, downloadSingleFileMethod);

      final args = call.arguments as Map;
      expect(args['url'], expectedUrl);
      expect(args['file_name'], expectedFileName);
      expect(args['save_to_photo'], expectedSaveToPhoto);

      if (error is PlatformException) {
        throw PlatformException(
          code: '400',
          message: 'Mock download failed',
        );
      }

      if (error is Exception) {
        throw Error();
      }

      return response;
    });
  }

  setUp(() {
    setupDownloadSingleFileMock(
      expectedUrl: 'https://example.com/test.pdf',
      expectedFileName: 'test.pdf',
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(downloadSingleFileMethodChannel, null);
  });

  test('successfully case', () async {
    setupDownloadSingleFileMock(
      expectedUrl: 'https://example.com/test.pdf',
      expectedFileName: 'test.pdf',
      expectedSaveToPhoto: false,
    );

    String? response;

    final result = await platform.downloadSingleFile(
      url: 'https://example.com/test.pdf',
      fileName: 'test.pdf',
      response: (res) => response = res,
    );

    expect(result, 'Download started successfully');
    expect(response, 'Download started successfully');
  });

  test('url empty case', () async {
    setupDownloadSingleFileMock(
        expectedUrl: '',
        expectedFileName: 'test.pdf',
        expectedSaveToPhoto: false,
        response: 'PlatformException()'
    );

    String? response;

    final result = await platform.downloadSingleFile(
      url: '',
      fileName: 'test.pdf',
      response: (res) => response = res,
    );

    expect(result, 'PlatformException()');
    expect(response, 'PlatformException()');
  });

  test('url null case', () async {
    setupDownloadSingleFileMock(
      expectedUrl: null,
      expectedFileName: 'test.pdf',
      expectedSaveToPhoto: false,
      response: "PlatformException()",
    );

    String? response;

    final result = await platform.downloadSingleFile(
        url: null,
        fileName: 'test.pdf',
        response: (res) => response = res
    );

    expect(result, 'PlatformException()');
    expect(response, 'PlatformException()');
  });

  test('file name empty case', () async {
    setupDownloadSingleFileMock(
      expectedUrl: null,
      expectedFileName: '',
      expectedSaveToPhoto: false,
      response: "PlatformException()",
    );

    String? response;

    final result = await platform.downloadSingleFile(
        url: null,
        fileName: '',
        response: (res) => response = res
    );

    expect(result, 'PlatformException()');
    expect(response, 'PlatformException()');
  });
}
