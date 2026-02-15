import Foundation
import UIKit
import UserNotifications

class NotificationHelper: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationHelper()
    
    private var lastUpdateTime: [String: Date] = [:]
    private let throttleInterval: TimeInterval = 2.0 // seconds
    
    private override init() {
        super.init()
    }
    
    // MARK: - Permission
    
    func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("⚠️ Notification permission error: \(error.localizedDescription)")
            }
            print("📢 Notification permission granted: \(granted)")
        }
    }
    
    // MARK: - Progress Notification
    
    func showProgressNotification(fileName: String, progress: Int) {
        // Throttle updates to avoid notification spam
        let now = Date()
        if let lastUpdate = lastUpdateTime[fileName],
           now.timeIntervalSince(lastUpdate) < throttleInterval,
           progress < 100 {
            return
        }
        lastUpdateTime[fileName] = now
        
        let content = UNMutableNotificationContent()
        content.title = "Downloading"
        content.body = "\(fileName) — \(progress)%"
        content.sound = nil // No sound for progress updates
        
        let request = UNNotificationRequest(
            identifier: notificationId(for: fileName),
            content: content,
            trigger: nil // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Failed to show progress notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Completion Notification
    
    func showCompletionNotification(fileName: String, filePath: String) {
        // Clean up throttle tracking
        lastUpdateTime.removeValue(forKey: fileName)
        
        let content = UNMutableNotificationContent()
        content.title = "Download Complete"
        content.body = "Tap to open \(fileName)"
        content.sound = .default
        content.userInfo = ["filePath": filePath, "fileName": fileName]
        
        let request = UNNotificationRequest(
            identifier: notificationId(for: fileName),
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Failed to show completion notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Failure Notification
    
    func showFailureNotification(fileName: String, message: String) {
        // Clean up throttle tracking
        lastUpdateTime.removeValue(forKey: fileName)
        
        let content = UNMutableNotificationContent()
        content.title = "Download Failed"
        content.body = "\(fileName): \(message)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: notificationId(for: fileName),
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Failed to show failure notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Called when the user taps on a notification
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let filePath = userInfo["filePath"] as? String {
            let fileURL = URL(fileURLWithPath: filePath)
            
            DispatchQueue.main.async {
                self.openFile(at: fileURL)
            }
        }
        
        completionHandler()
    }
    
    /// Called when a notification is delivered while the app is in the foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show the notification even when the app is in the foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
    
    // MARK: - Open File
    
    private var documentController: UIDocumentInteractionController?
    
    private func openFile(at url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("⚠️ File not found at: \(url.path)")
            return
        }
        
        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
            print("⚠️ No root view controller found")
            return
        }
        
        // Keep a strong reference so it doesn't deallocate
        documentController = UIDocumentInteractionController(url: url)
        
        if !documentController!.presentPreview(animated: true) {
            // If preview isn't available, show the "Open In" menu
            documentController!.presentOptionsMenu(from: rootVC.view.bounds, in: rootVC.view, animated: true)
        }
    }
}

// MARK: - UIDocumentInteractionControllerDelegate

extension NotificationHelper: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return UIApplication.shared.keyWindow?.rootViewController ?? UIViewController()
    }
}
