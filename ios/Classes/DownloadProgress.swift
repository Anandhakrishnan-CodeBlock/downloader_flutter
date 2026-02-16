class DownloadProgress {

    static func statusStarted(fileName: String, filePath: String? = nil) -> [String: Any] {
        return [
            "status": "started",
            "fileName": fileName,
            "filePath": filePath as Any
        ]
    }

    static func statusProgress(fileName: String, progress: Int, filePath: String? = nil) -> [String: Any] {
        return [
            "status": "progress",
            "fileName": fileName,
            "progress": progress,
            "filePath": filePath as Any
        ]
    }

    static func statusCompleted(fileName: String, filePath: String? = nil) -> [String: Any] {
        return [
            "status": "completed",
            "fileName": fileName,
            "filePath": filePath as Any
        ]
    }

    static func statusSaved(fileName: String, filePath: String? = nil) -> [String: Any] {
        return [
            "status": "saved",
            "fileName": fileName,
            "filePath": filePath as Any
        ]
    }
    
    static func statusSuccess(fileName: String, filePath: String? = nil) -> [String: Any] {
        return [
            "status": "success",
            "fileName": fileName,
            "filePath": filePath as Any
        ]
    }

    static func statusFailed(fileName: String, message: String, filePath: String? = nil) -> [String: Any] {
        return [
            "status": "failed",
            "fileName": fileName,
            "message": message,
            "filePath": filePath as Any
        ]
    }

    static func statusError(fileName: String, message: String, filePath: String? = nil) -> [String: Any] {
        return [
            "status": "error",
            "fileName": fileName,
            "message": message,
            "filePath": filePath as Any
        ]
    }
}
