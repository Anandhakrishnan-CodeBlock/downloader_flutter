import 'download_status.dart';

class DownloadTask {
  final int id;
  final String? workId;
  final String fileName;
  final String url;
  final DownloadStatus status;
  final double percentage;
  final int downloadedBytes;
  final int totalBytes;
  final String? fileUri;
  final String? mimeType;
  final int maxRetry;
  final int retried;
  final bool isImmediate;
  final bool isWifiOnly;
  final bool isPowerSavingEnabled;
  final bool isOneByOne;
  final bool showToast;
  final String? errorMessage;
  final DateTime createdAt;

  const DownloadTask({
    required this.id,
    this.workId,
    required this.fileName,
    required this.url,
    required this.status,
    required this.percentage,
    required this.downloadedBytes,
    required this.totalBytes,
    this.fileUri,
    this.mimeType,
    required this.maxRetry,
    required this.retried,
    required this.isImmediate,
    required this.isWifiOnly,
    required this.isPowerSavingEnabled,
    required this.isOneByOne,
    required this.showToast,
    this.errorMessage,
    required this.createdAt,
  });

  factory DownloadTask.fromMap(Map<String, dynamic> map) {
    return DownloadTask(
      id: (map['id'] as num?)?.toInt() ?? 0,
      workId: map['workId'] as String?,
      fileName: map['fileName'] as String? ?? '',
      url: map['url'] as String? ?? '',
      status: DownloadStatus.fromString(map['status'] as String?),
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      downloadedBytes: (map['downloadedBytes'] as num?)?.toInt() ?? 0,
      totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
      fileUri: map['fileUri'] as String?,
      mimeType: map['mimeType'] as String?,
      maxRetry: (map['maxRetry'] as num?)?.toInt() ?? 3,
      retried: (map['retried'] as num?)?.toInt() ?? 0,
      isImmediate: map['isImmediate'] as bool? ?? true,
      isWifiOnly: map['isWifiOnly'] as bool? ?? false,
      isPowerSavingEnabled: map['isPowerSavingEnabled'] as bool? ?? false,
      isOneByOne: map['isOneByOne'] as bool? ?? false,
      showToast: map['showToast'] as bool? ?? false,
      errorMessage: map['errorMessage'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}