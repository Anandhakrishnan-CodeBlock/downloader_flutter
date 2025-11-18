import Flutter
import UIKit

public class DownloaderFlutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    var eventSink: FlutterEventSink?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        
        let instance = DownloaderFlutterPlugin()
        
        let downloadSingleFileMethodChannel = FlutterMethodChannel(name: "download_single_file_method_channel",binaryMessenger:registrar.messenger())
        let downloadMultipleFileMethodChannel = FlutterMethodChannel(name: "download_multiple_file_method_channel",binaryMessenger:registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "download_progress_events", binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(instance, channel: downloadSingleFileMethodChannel)
        registrar.addMethodCallDelegate(instance, channel: downloadMultipleFileMethodChannel)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let downloadManager = DownloadManager()
        switch call.method {
        case "downloadSingleFileMethod":
            if let args = call.arguments as? [String: Any],
               let url = args["url"] as? String,
               let fileName = args["file_name"] as? String,
                let saveToPhotos = args["save_to_photo"] as? Bool {
                print("📦 URL: \(url)")
                print("📄 File name: \(fileName)")
                
                downloadManager.downloadSingleFile(
                    from: url,
                    fileName: fileName,
                    saveToPhotos: saveToPhotos,
                    completion: { message in
                        result("\(message)")
                    },
                    progressCallback: { progress in
                        DispatchQueue.main.async {
                            self.eventSink?(progress)
                        }
                    }
                    
                )
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS",
                                    message: "Missing url or file_name",
                                    details: nil))
            }
            
        case "downloadMultipleFileMethod":
            if let args = call.arguments as? [String: Any],
               let urls = args["urls"] as? [String],
               let fileNames = args["file_names"] as? [String],
               let saveToPhotos = args["save_to_photo"] as? Bool {
                print("📦 URL: \(urls)")
                print("📄 File name: \(fileNames)")
                
                downloadManager.downloadMultipleFiles(
                    from: urls,
                    fileNames: fileNames,
                    saveToPhotos: saveToPhotos,
                    completion: { message in
                        result("\(message)")
                    },
                    progressCallback: { progress in
                        DispatchQueue.main.async {
                            self.eventSink?(progress)
                        }
                    }
                    
                )
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS",
                                    message: "Missing urls or file_names",
                                    details: nil))
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
