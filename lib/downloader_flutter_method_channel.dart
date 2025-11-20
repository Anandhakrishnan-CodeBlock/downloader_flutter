import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'downloader_flutter_platform_interface.dart';

/// MethodChannelDownloaderFlutter
/// MethodChannelDownloaderFlutter is a class extended from DownloaderFlutterPlatform
/// This class responsible to communicate with native environment
/// It hold the declaration for both method and event chanel

class MethodChannelDownloaderFlutter extends DownloaderFlutterPlatform {

  @visibleForTesting
  static const downloadSingleFileMethodChannel = MethodChannel('download_single_file_method_channel');
  static const downloadSingleFileMethod = 'downloadSingleFileMethod';
  static const downloadMultipleFileMethodChannel = MethodChannel('download_multiple_file_method_channel');
  static const downloadMultipleFileMethod = 'downloadMultipleFileMethod';
  static const downloadProgressEventChannel = EventChannel('download_progress_events');
  Stream<Map<String, dynamic>>? downloadProgressStatus;

  @override
  Future<String?> downloadSingleFile({
    required String? url,
    required String fileName,
    required Function response,
    bool? saveToPhoto = false,
    bool? showToastAndroid = false
  }) async {
    try {
      final result = await downloadSingleFileMethodChannel.invokeMethod<String>(
          downloadSingleFileMethod, {'url': url,
        'file_name': fileName,
        'save_to_photo': saveToPhoto,
        'show_toast': showToastAndroid
      });
      response(result);
      return result;
    } on PlatformException catch (e) {
      debugPrint("PlatformException: ${e.code} - ${e.message}");
      response(e);
      return "PlatformException: ${e.code} - ${e.message}";
    } catch (e) {
      response(e);
      return "Exception: $e";
    }
  }

  @override
  Future<String?> downloadMultipleFile({
    required List<String?> urls,
    required List<String> fileNames,
    required Function response,
    bool? saveToPhoto = false,
    bool? showToastAndroid = false
  }) async {
    try {
      final result = await downloadMultipleFileMethodChannel.invokeMethod<String>(
          downloadMultipleFileMethod, { 'urls': urls,
        'file_names': fileNames,
        'save_to_photo': saveToPhoto,
        'show_toast': showToastAndroid
      });
      response(result);
      return result;
    } on PlatformException catch (e) {
      debugPrint("PlatformException: ${e.code} - ${e.message}");
      response(e);
      return "PlatformException: ${e.code} - ${e.message}";
    } catch (e) {
      response(e);
      return "Exception: $e";
    }
  }

  @override
  Stream<Map<String, dynamic>> downloadProgress() async* {
    try {
      downloadProgressStatus ??= downloadProgressEventChannel.receiveBroadcastStream()
          .map((event) => Map<String, dynamic>.from(event));
    } on PlatformException catch (e) {
      debugPrint("PlatformException: ${e.code} - ${e.message}");
    } catch (e) {
      debugPrint("Exception: $e");
    }
    yield* downloadProgressStatus!;
  }
}
