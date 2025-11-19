# Downloader Flutter

A powerful Flutter download plugin supporting Android & iOS with real-time progress, parallel downloads, background safety, system [DownloadManager](https://developer.android.com/reference/android/app/DownloadManager) integration, iOS [URLSessionDownloadDelegate](https://developer.apple.com/documentation/foundation/urlsessiondownloaddelegate) support, automatic file saving, Photos library export, and EventChannel-based streaming updates. Designed for handling large files with accurate progress tracking and smooth cross-platform performance.

Flutter Downloader Plugin
A full-featured, cross-platform file downloader built for Flutter, supporting Android & iOS with real-time progress, safe background execution, system-level integrations, and a clean EventChannel-driven update stream.

This plugin provides advanced download capabilities:

### Android Demo 
https://github.com/Anandhakrishnan-CodeBlock/downloader_flutter/blob/main/assets/Android_Downloader_Flutter.mov

### iOS Demo
https://github.com/Anandhakrishnan-CodeBlock/downloader_flutter/blob/main/assets/iOS_Downloader_Flutter.mov

# 🚀 Features

## Android Support

- Uses Android DownloadManager for reliable system-level downloading

- Supports parallel / multiple downloads simultaneously

- Real-time progress updates using EventChannel

- Safe background execution using coroutines (Dispatchers.IO)

- Automatic file handling and storage management

- Saves images/videos to Gallery when requested

- Toast feedback for start/error (optional)

- Thread-safe updates using Dispatchers.Main

- Kotlin implementation optimized for performance

## iOS Support

- Uses URLSessionDownloadDelegate for accurate progress tracking

- Supports true percentage (%) progress

- Parallel file downloads with per-file delegates

- Automatic movement of temporary downloaded files

- Optional save to Photos app

- Sends real-time events using Flutter EventChannel

- 100% main-thread safe event dispatching

- Swift implementation with clean status mapping

## Support
| Platform | Status |
|:--------:|:------:|
| Android  |   ✅    |
|   iOS    |   ✅    |
| Windows  |   ❌    |
|  Linux   |   ❌    |
|  macOs   |   ❌    |

# Plugin Configuration
## Android (Permission)
- Internet Permission Required
```

<uses-permission android:name="android.permission.INTERNET" />
```

## iOS (Info.plist)
### 1. Photo Library Access (required)
> Because your code calls PHPhotoLibrary.requestAuthorization(...) and saves images/videos.
```
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app saves downloaded media files to your Photos library.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your Photos to save and view downloaded files.</string>
```

### 2. App Transport Security (for HTTP downloads)
> If any of your download URLs use HTTP (not HTTPS), iOS will block them unless you add this:
- Option A – Allow only specific domains (recommended)
```
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>commondatastorage.googleapis.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
        </dict>
    </dict>
</dict>
```

- Option B – Allow all HTTP (for testing only)
```
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

### 3. File Sharing (for “On My iPhone → AppName”)
> To let users see downloaded files in the Files app:
```
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

### 4. Background downloads (optional but recommended)
> If you want downloads to continue when the app goes into the background:
```
<key>UIBackgroundModes</key>
	<array>
		<string>fetch</string>
		<string>processing</string>
    </array>
```
# Usage
- Object creation for DownloaderFlutter() class.
```

final _downloaderFlutterPlugin = DownloaderFlutter();
```
## Single file download
```
    await _downloaderFlutterPlugin.downloadSingleFile(
        url: 'https://images.pexels.com/photos/10725897/pexels-photo-10725897.jpeg',
        fileName: "image.jpeg",
         saveToPhoto: true, (Optional)
         showToastAndroid: false, (Optional)
         response: (data) {
             debugPrint("Response In App: $data");
         },
    ) ?? 'Downloader Not Connected';
```
#### Properties downloadSingleFile 
| **Property**         | **Type** |      **Example Value**       | **Description**                                                           |  
|:---------------------|:--------:|:----------------------------:|:--------------------------------------------------------------------------|
| **url**              |  String  | https://example.com/file.mp4 | The full download URL of the file.                                        |
| **fileName**         |  String  |         my_video.mp4         | Name of the saved file, including its extension.                          |
| **saveToPhoto**      |   bool   |          true/false          | iOS only — when true, saves downloaded media files to the Photos app.     |
| **showToastAndroid** |   bool   |          true/false          | Android only — when true, shows a toast message after download completes. |
| **response**         |  String  |    "success" or "failed"     | String response/status returned by the function.                          |

## Multiple file download
```
    await _downloaderFlutterPlugin.downloadMultipleFile(
        urls: [
          'https://images.pexels.com/photos/177598/pexels-photo-177598.jpeg',
          'https://images.pexels.com/photos/577585/pexels-photo-577585.jpeg',
          'https://images.pexels.com/photos/1181244/pexels-photo-1181244.jpeg',
          'https://images.pexels.com/photos/4816921/pexels-photo-4816921.jpeg',
          'https://images.pexels.com/photos/248515/pexels-photo-248515.png',
        ],
        fileNames: [
          'image1.jpg',
          'image2.jpg',
          'image3.jpg',
          'image4.jpg',
          'image5.png',
        ],
        saveToPhoto: true, (Optional)
        showToastAndroid: true, (Optional)
        response: (data) {
          debugPrint("Response In App: $data");
        },
      ) ?? 'Downloader Not Connected';
```
#### Properties downloadMultipleFile
| **Property**         |   **Type**   |                     **Example Value**                      | **Description**                                                           |  
|:---------------------|:------------:|:----------------------------------------------------------:|:--------------------------------------------------------------------------|
| **urls**             | List<String> | ["https://example.com/a.mp4", "https://example.com/b.jpg"] | The full download URL of the file.                                        |
| **fileNames**        | List<String> |                ["video1.mp4", "image1.jpg"]                | Name of the saved file, including its extension.                          |
| **saveToPhoto**      |     bool     |                         true/false                         | iOS only — when true, saves downloaded media files to the Photos app.     |
| **showToastAndroid** |     bool     |                         true/false                         | Android only — when true, shows a toast message after download completes. |
| **response**         |    String    |                   "success" or "failed"                    | String response/status returned by the function.                          |

## Event listener for downloadProgress
```

    _downloaderFlutterPlugin.downloadProgress().listen((event) {
        handleDownloadEvent(event);
    });
```

## Download handler 
```
    void handleDownloadEvent(Map<String, dynamic> event) {
    
    final status = event["status"] as String?;
    
    if (status == null) {
      debugPrint("⚠️ Unknown event: $event");
      return;
    }

    final fileName = event["fileName"] as String? ?? "unknown";

    switch (status) {
      case "started":
        debugPrint("🚀 Started $fileName");
        break;

      case "progress":
        final progress = event["progress"] as int? ?? 0;
        debugPrint("📊 Progress $fileName: $progress%");
        break;

      case "success":
        debugPrint("✅ Completed $fileName");
        break;

      case "saved":
        debugPrint("📷 Saved to photo $fileName");
        break;

      case "failed":
        debugPrint("❌ Failed $fileName");
        break;

      case "completed":
        debugPrint("🎉 Download completed $fileName");
        break;

      case "error":
        final message = event["message"] as String? ?? "Unknown error";
        debugPrint("⚠️ Error: $message");
        break;

      default:
        debugPrint("❓ Unknown status: $status");
    }
  }
```
#### Properties handleDownloadEvent
| **Status Value** |          **When Triggered**          |                      **Meaning / Behavior**                       |  
|:-----------------|:------------------------------------:|:-----------------------------------------------------------------:|
| **started**      |         When download begins         |        Indicates download has started for the given file.         |
| **progress**     |        During active download        |          Provides incremental progress updates (0–100).           |
| **success**      | When file is successfully downloaded |    File is saved locally in the device's documents directory.     |
| **saved**        | When file saved to Photos (iOS only) |  Confirms that the media file has been added to the Photos app.   |
| **failed**       |         When download fails          | File couldn’t be downloaded due to error (e.g., network failure). |
| **completed**    | When all download operations finish  |   Indicates full workflow completed (download + optional save).   |
| **error**        |    When an internal error occurs     |       Provides an error message detailing what went wrong.        |

# Bugs/Requests
Feel free to open an issue if you encounter any problems or think that the plugin is missing some feature.
