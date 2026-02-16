import Foundation

/// Manages background URLSession completion handlers provided by iOS.
/// When iOS wakes the app to handle background session events, it provides
/// a completion handler that must be called after all events are processed.
public class BackgroundSessionManager {
    
    public static let shared = BackgroundSessionManager()
    
    /// Stored completion handlers keyed by session identifier
    private var completionHandlers: [String: () -> Void] = [:]
    
    private init() {}
    
    /// Store a completion handler for a given session identifier.
    public func setCompletionHandler(_ handler: @escaping () -> Void, for identifier: String) {
        completionHandlers[identifier] = handler
    }
    
    /// Call and remove the completion handler for a given session identifier.
    public func callCompletionHandler(for identifier: String) {
        DispatchQueue.main.async {
            self.completionHandlers[identifier]?()
            self.completionHandlers.removeValue(forKey: identifier)
        }
    }
}
