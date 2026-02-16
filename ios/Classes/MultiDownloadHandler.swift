import Foundation
import UIKit

class MultiDownloadHandler: NSObject, URLSessionDownloadDelegate {
    
    let fileName: String
    let saveToPhotos: Bool
    let progressCallback: ([String: Any]) -> Void
    let onFinish: () -> Void
    let sessionIdentifier: String
    
    init(fileName: String,
         saveToPhotos: Bool,
         progressCallback: @escaping ([String: Any]) -> Void,
         onFinish: @escaping () -> Void) {
        self.fileName = fileName
        self.saveToPhotos = saveToPhotos
        self.progressCallback = progressCallback
        self.onFinish = onFinish
        self.sessionIdentifier = "com.downloader.flutter.multi.\(UUID().uuidString)"
    }
    
    /// Creates a background URLSession for this handler
    func createBackgroundSession() -> URLSession {
        let config = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Int(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100)
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documents.appendingPathComponent(fileName)
        
        self.progressCallback(DownloadProgress.statusProgress(fileName: self.fileName, progress: progress, filePath: destinationURL.path))
        
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documents.appendingPathComponent(fileName)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)
            
            // 🔵 COMPLETED
            self.progressCallback(DownloadProgress.statusCompleted(fileName: self.fileName, filePath: destinationURL.path))
            
            // 🔵 SUCCESS
            self.progressCallback(DownloadProgress.statusSuccess(fileName: self.fileName, filePath: destinationURL.path))
            
            
            if saveToPhotos {
                SaveToPhoto().saveMediaToPhotos(from: destinationURL) { success, _ in
                    if success {
                        self.progressCallback(DownloadProgress.statusSaved(fileName: self.fileName, filePath: destinationURL.path))
                    }
                }
            }
            
        } catch {
            self.progressCallback(DownloadProgress.statusError(fileName: self.fileName, message: "Move error: \(error.localizedDescription)"))
        }
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        if let error = error {
            self.progressCallback(DownloadProgress.statusFailed(fileName: self.fileName, message: error.localizedDescription))
            
        } else {
            self.progressCallback(DownloadProgress.statusSuccess(fileName: self.fileName, filePath: nil))
        }
        onFinish()
    }
    
    // 🔵 Called when all background session events have been delivered
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        BackgroundSessionManager.shared.callCompletionHandler(for: sessionIdentifier)
    }
}
