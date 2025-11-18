import Photos
import UIKit

class SaveToPhoto {
    func saveMediaToPhotos(from fileURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        // Request permission if needed
        PHPhotoLibrary.requestAuthorization { status in
            var isAuthorized = false
                
                if #available(iOS 14, *) {
                    // iOS 14 and above: handle both .authorized and .limited
                    isAuthorized = (status == .authorized || status == .limited)
                } else {
                    // iOS 13 and below: only .authorized exists
                    isAuthorized = (status == .authorized)
                }
                
                guard isAuthorized else {
                    print("❌ Photo Library access denied")
                    completion(false, nil)
                    return
                }

            let fileExtension = fileURL.pathExtension.lowercased()
            PHPhotoLibrary.shared().performChanges({
                if ["jpg", "jpeg", "png", "heic"].contains(fileExtension) {
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
                } else if ["mov", "mp4", "m4v"].contains(fileExtension) {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
                }
            }, completionHandler: { success, error in
                if success {
                    print("📸 Saved to Photos: \(fileURL.lastPathComponent)")
                } else if let error = error {
                    print("❌ Save to Photos failed: \(error.localizedDescription)")
                }
                completion(success, error)
            })
        }
    }
}

