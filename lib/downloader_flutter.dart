
import 'downloader_flutter_platform_interface.dart';

/// DownloaderFlutter
/// DownloaderFlutter is a class provide methods to download files
/// downloadSingleFile() method support single file download support
/// downloadMultipleFile() method support multiple files download
/// downloadProgress() event support to provide states for downloading file

class DownloaderFlutter {

  /// Downloads a single file from the given [url], [fileName], [response] are required fields.
  /// Optional fields [saveToPhoto] and [showToastAndroid]
  /// Returns the downloaded success or throws a [PlatformException].
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

  /// Downloads a multiple file from the given [urls], [fileNames], [response] are required fields.
  /// Optional fields [saveToPhoto] and [showToastAndroid]
  /// Returns the downloaded success or throws a [PlatformException].
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

  /// Downloads progress is to provide live status for the downloading file.
  /// Returns the downloaded status [Map] or throws a [PlatformException].
  Stream<Map<String, dynamic>> downloadProgress() async* {
    yield* DownloaderFlutterPlatform.instance.downloadProgress();
  }
}
