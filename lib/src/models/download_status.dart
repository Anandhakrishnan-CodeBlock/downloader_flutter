enum DownloadStatus {
  queued,
  running,
  paused,
  completed,
  failed,
  cancelled,
  unknown;

  static DownloadStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'QUEUED':
        return DownloadStatus.queued;
      case 'RUNNING':
        return DownloadStatus.running;
      case 'PAUSED':
        return DownloadStatus.paused;
      case 'COMPLETED':
        return DownloadStatus.completed;
      case 'FAILED':
        return DownloadStatus.failed;
      case 'CANCELLED':
        return DownloadStatus.cancelled;
      default:
        return DownloadStatus.unknown;
    }
  }
}