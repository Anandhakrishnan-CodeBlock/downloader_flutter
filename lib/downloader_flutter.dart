
import 'downloader_flutter_platform_interface.dart';

class DownloaderFlutter {
  Future<String?> getPlatformVersion() {
    return DownloaderFlutterPlatform.instance.getPlatformVersion();
  }
}
