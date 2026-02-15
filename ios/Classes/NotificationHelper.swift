import Foundation
import UIKit
import UserNotifications

@objc class NotificationHelper: NSObject, UNUserNotificationCenterDelegate {
    
    @objc static let shared = NotificationHelper()
    
    private var lastUpdateTime: [String: Date] = [:]
    private let throttleInterval: TimeInterval = 2.0 // seconds
    private var documentController: UIDocumentInteractionController?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Permission
    
    @objc func requestPermission() {
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
    
    @objc func showProgressNotification(fileName: String, progress: Int) {
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
        content.sound = nil
        
        let request = UNNotificationRequest(
            identifier: notificationId(for: fileName),
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    // MARK: - Completion Notification
    
    @objc func showCompletionNotification(fileName: String, filePath: String) {
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
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    // MARK: - Failure Notification
    
    @objc func showFailureNotification(fileName: String, message: String) {
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
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
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
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
    
    // MARK: - Open File
    
    private func openFile(at url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("⚠️ File not found at: \(url.path)")
            return
        }
        
        guard let rootVC = Self.topViewController() else {
            print("⚠️ No root view controller found")
            return
        }
        
        documentController = UIDocumentInteractionController(url: url)
        documentController?.delegate = self
        
        if !(documentController?.presentPreview(animated: true) ?? false) {
            documentController?.presentOptionsMenu(from: rootVC.view.bounds, in: rootVC.view, animated: true)
        }
    }
    
    // MARK: - Helpers
    
    private func notificationId(for fileName: String) -> String {
        return "download_\(fileName)"
    }
    
    private static func topViewController() -> UIViewController? {
        if #available(iOS 13.0, *) {
            guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                  let window = scene.windows.first(where: { $0.isKeyWindow }) else {
                return nil
            }
            return window.rootViewController
        } else {
            return UIApplication.shared.keyWindow?.rootViewController
        }
    }
}

// MARK: - UIDocumentInteractionControllerDelegate

extension NotificationHelper: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return Self.topViewController() ?? UIViewController()
    }
}
