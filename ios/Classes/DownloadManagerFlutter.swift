import Foundation
import UIKit

class DownloadManager: NSObject, URLSessionDownloadDelegate {
    
    // MARK: - Callbacks
    var progressCallback: (([String: Any]) -> Void)?
    var completionCallback: ((String) -> Void)?
    
    // MARK: - Properties
    let saveToPhoto = SaveToPhoto()
    var fileName: String = ""
    var saveToPhotosEnabled: Bool = false
    
    // Custom URLSession with delegate
    lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    // MARK: - MAIN DOWNLOAD FUNCTION
    
    func downloadSingleFile(
        from urlString: String,
        fileName: String,
        saveToPhotos: Bool,
        completion: @escaping (String) -> Void,
        progressCallback: @escaping ([String: Any]) -> Void
    ) {
        self.fileName = fileName
        self.progressCallback = progressCallback
        self.completionCallback = completion
        self.saveToPhotosEnabled = saveToPhotos
        
        guard let url = URL(string: urlString) else {
            progressCallback(DownloadProgress.statusFailed(fileName: fileName, message: "Invalid URL: \(urlString)"))
            completion("Invalid URL: \(fileName)")
            return
        }
        
        // 🔵 Send START status
        progressCallback(DownloadProgress.statusStarted(fileName: fileName))
        completion("Single File Download Started")
        
        // Start using delegate-based session for progress
        let task = session.downloadTask(with: url)
        task.resume()
    }
    
    func downloadMultipleFiles(
        from urlStrings: [String],
        fileNames: [String],
        saveToPhotos: Bool,
        completion: @escaping (String) -> Void,
        progressCallback: @escaping ([String: Any]) -> Void
    ) {
        guard urlStrings.count == fileNames.count else {
            progressCallback(DownloadProgress.statusError(fileName: "multiple", message: "Count mismatch"))
            completion("Url and File Name Count mismatch")
            return
        }
        
        let dispatchGroup = DispatchGroup()
        
        for i in urlStrings.indices {
            let urlString = urlStrings[i]
            let fname = fileNames[i]
            
            guard let url = URL(string: urlString) else {
                progressCallback(DownloadProgress.statusFailed(fileName: fname, message: "Invalid URL"))
                continue
            }
            
            progressCallback(DownloadProgress.statusStarted(fileName: fname))
            
            // Each file uses a temporary delegate wrapper
            dispatchGroup.enter()
            
            let delegate = MultiDownloadHandler(
                fileName: fname,
                saveToPhotos: saveToPhotos,
                progressCallback: progressCallback,
                onFinish: {
                    dispatchGroup.leave()
                }
            )
            
            let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            session.downloadTask(with: url).resume()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion("All files completed")
        }
    }
    
    // MARK: - URLSession Delegates
    
    // 🔵 PROGRESS (%)
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        
        guard totalBytesExpectedToWrite > 0 else { return }
        
        let progress = Int((Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)) * 100)
        
        self.progressCallback?(DownloadProgress.statusProgress(fileName: self.fileName, progress: progress))
    }
    
    // 🔵 COMPLETED → File moved to Documents folder
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
            self.progressCallback?(DownloadProgress.statusCompleted(fileName: self.fileName))
            
            // 🔵 SAVE TO PHOTOS
            if saveToPhotosEnabled {
                self.saveToPhoto.saveMediaToPhotos(from: destinationURL) { success, _ in
                    if success {
                        self.progressCallback?(DownloadProgress.statusSaved(fileName: self.fileName))
                    }
                }
            }
            
        } catch {
            self.progressCallback?(DownloadProgress.statusError(fileName: self.fileName, message: "File move error: \(error)"))
            completionCallback?("Download Failed: \(fileName)")
        }
    }
    
    // 🔵 ERROR or FINAL SUCCESS
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        
        if let error = error {
            self.progressCallback?(DownloadProgress.statusFailed(fileName: self.fileName, message: error.localizedDescription))
            completionCallback?("Download Failed: \(fileName)")
            return
        }
        
        // 🔵 FINAL SUCCESS
        self.progressCallback?(DownloadProgress.statusSuccess(fileName: self.fileName))
        self.completionCallback?("Download Success: \(self.fileName)")
    }
}


