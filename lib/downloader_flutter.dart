
import 'downloader_flutter_platform_interface.dart';

class DownloaderFlutter {
  Future<String?> downloadSingleFile({
    required String? url,
    required String fileName,
    required Function response,
    bool? saveToPhoto = false,
    bool? showToastAndroid = false}) async {
    return await DownloaderFlutterPlatform.instance.downloadSingleFile(
        url: url,
        fileName: fileName,
        saveToPhoto: saveToPhoto,
        showToastAndroid: showToastAndroid,
        response: response);
  }

  Future<String?> downloadMultipleFile({
    required List<String?> urls,
    required List<String> fileNames,
    required Function response,
    bool? saveToPhoto = false,
    bool? showToastAndroid = false}) async {
    return await DownloaderFlutterPlatform.instance.downloadMultipleFile(
        urls: urls,
        fileNames: fileNames,
        saveToPhoto: saveToPhoto,
        showToastAndroid: showToastAndroid,
        response: response);
  }

  Stream<Map<String, dynamic>> downloadProgress() async* {
    yield* DownloaderFlutterPlatform.instance.downloadProgress();
  }
}
