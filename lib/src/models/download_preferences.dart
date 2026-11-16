class DownloadPreferences {
  final bool isImmediate;
  final bool isWifiOnly;
  final bool isPowerSavingEnabled;
  final bool isOneByOne;
  final bool showToastAndroid;
  final int maxRetry;

  const DownloadPreferences({
    this.isImmediate = true,
    this.isWifiOnly = false,
    this.isPowerSavingEnabled = false,
    this.isOneByOne = false,
    this.showToastAndroid = false,
    this.maxRetry = 3,
  });

  DownloadPreferences copyWith({
    bool? isImmediate,
    bool? isWifiOnly,
    bool? isPowerSavingEnabled,
    bool? isOneByOne,
    bool? showToastAndroid,
    int? maxRetry,
  }) {
    return DownloadPreferences(
      isImmediate: isImmediate ?? this.isImmediate,
      isWifiOnly: isWifiOnly ?? this.isWifiOnly,
      isPowerSavingEnabled: isPowerSavingEnabled ?? this.isPowerSavingEnabled,
      isOneByOne: isOneByOne ?? this.isOneByOne,
      showToastAndroid: showToastAndroid ?? this.showToastAndroid,
      maxRetry: maxRetry ?? this.maxRetry,
    );
  }

  Map<String, dynamic> toMap() => {
    'isImmediate': isImmediate,
    'isWifiOnly': isWifiOnly,
    'isPowerSavingEnabled': isPowerSavingEnabled,
    'isOneByOne': isOneByOne,
    'showToastAndroid': showToastAndroid,
    'maxRetry': maxRetry,
  };
}

class DownloadRequestItem {
  final String url;
  final String fileName;

  const DownloadRequestItem({
    required this.url,
    required this.fileName,
  });

  Map<String, String> toMap() => {
    'url': url,
    'fileName': fileName,
  };
}