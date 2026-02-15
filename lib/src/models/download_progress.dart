/// Represents the various states of a download process.
enum DownloadStatus {
  /// The download task has been initialized and started.
  started,

  /// The file is currently being downloaded.
  /// The [DownloadProgress.progress] field will contain the current percentage.
  progress,

  /// The download process is physically complete.
  completed,

  /// Specifically indicates that the downloaded file has been successfully
  /// saved to the photo/video gallery.
  saved,

  /// The download finished successfully from the system's perspective.
  success,

  /// The download task failed.
  failed,

  /// An error occurred during the download or post-processing.
  error;

  /// Returns the matching [DownloadStatus] from a given string.
  ///
  /// This handles case-insensitive matching for all 7 statuses.
  static DownloadStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'started':
        return DownloadStatus.started;
      case 'progress':
      case 'downloading':
        return DownloadStatus.progress;
      case 'completed':
        return DownloadStatus.completed;
      case 'saved':
        return DownloadStatus.saved;
      case 'success':
        return DownloadStatus.success;
      case 'failed':
        return DownloadStatus.failed;
      case 'error':
        return DownloadStatus.error;
      default:
        return DownloadStatus.error;
    }
  }
}

/// Represents the progress and status of an ongoing or completed download.
class DownloadProgress {
  /// The original name of the file being downloaded.
  final String fileName;

  /// The local path where the file is being or has been saved.
  ///
  /// This may be available during [DownloadStatus.progress] and is
  /// guaranteed during [DownloadStatus.success] or [DownloadStatus.completed].
  final String? filePath;

  /// The current state of the download.
  final DownloadStatus status;

  /// The download progress percentage, from 0 to 100.
  final int progress;

  /// A descriptive message, typically populated when [status] is [DownloadStatus.failed] or [DownloadStatus.error].
  final String? message;

  DownloadProgress({
    required this.fileName,
    this.filePath,
    required this.status,
    this.progress = 0,
    this.message,
  });

  /// Creates a [DownloadProgress] instance from a [Map].
  ///
  /// Primarily used to decode data sent from the native platform.
  factory DownloadProgress.fromMap(Map<String, dynamic> map) {
    return DownloadProgress(
      fileName: map['fileName'] ?? '',
      filePath: map['filePath'],
      status: DownloadStatus.fromString(map['status'] ?? 'error'),
      progress: map['progress'] ?? 0,
      message: map['message'],
    );
  }

  /// Converts this instance into a [Map].
  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'progress': progress,
      'fileName': fileName,
      'filePath': filePath,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'DownloadProgress(fileName: $fileName, status: $status, progress: $progress, filePath: $filePath, message: $message)';
  }
}
