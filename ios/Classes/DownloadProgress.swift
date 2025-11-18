class DownloadProgress {

    static func statusStarted(fileName: String) -> [String: Any] {
        return [
            "status": "started",
            "fileName": fileName
        ]
    }

    static func statusProgress(fileName: String, progress: Int) -> [String: Any] {
        return [
            "status": "progress",
            "fileName": fileName,
            "progress": progress
        ]
    }

    static func statusCompleted(fileName: String) -> [String: Any] {
        return [
            "status": "completed",
            "fileName": fileName
        ]
    }

    static func statusSaved(fileName: String) -> [String: Any] {
        return [
            "status": "saved",
            "fileName": fileName
        ]
    }
    
    static func statusSuccess(fileName: String) -> [String: Any] {
           return ["status": "success", "fileName": fileName]
       }

    static func statusFailed(fileName: String, message: String) -> [String: Any] {
        return [
            "status": "failed",
            "fileName": fileName,
            "message": message
        ]
    }

    static func statusError(fileName: String, message: String) -> [String: Any] {
        return [
            "status": "error",
            "fileName": fileName,
            "message": message
        ]
    }
}
