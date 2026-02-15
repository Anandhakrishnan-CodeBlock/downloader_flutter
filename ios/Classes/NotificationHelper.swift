import Foundation
import UserNotifications

class NotificationHelper {
    
    static let shared = NotificationHelper()
    
    private var lastUpdateTime: [String: Date] = [:]
    private let throttleInterval: TimeInterval = 2.0 // seconds
    
    private init() {}
    
    // MARK: - Permission
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
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
    
    func showCompletionNotification(fileName: String) {
        // Clean up throttle tracking
        lastUpdateTime.removeValue(forKey: fileName)
        
        let content = UNMutableNotificationContent()
        content.title = "Download Complete"
        content.body = "\(fileName)"
        content.sound = .default
        
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
    
    // MARK: - Helpers
    
    private func notificationId(for fileName: String) -> String {
        return "download_\(fileName)"
    }
}
