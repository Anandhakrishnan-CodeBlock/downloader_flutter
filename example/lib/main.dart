import 'package:downloader_flutter/downloader_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: DownloadManagerExampleScreen()));
}

class DownloadManagerExampleScreen extends StatefulWidget {
  const DownloadManagerExampleScreen({super.key});

  @override
  State<DownloadManagerExampleScreen> createState() =>
      _DownloadManagerExampleScreenState();
}

class _DownloadManagerExampleScreenState
    extends State<DownloadManagerExampleScreen> {
  final _downloader = DownloaderFlutter();

  DownloadPreferences _preferences = const DownloadPreferences(
    isImmediate: true,
    isWifiOnly: false,
    isPowerSavingEnabled: false,
    isOneByOne: false,
    showToastAndroid: false,
  );

  @override
  void initState() {
    super.initState();
    _downloader.requestNotificationPermission();
  }

  Future<void> _startSingleDownload() async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    await _downloader.downloadSingleFile(
      url: 'https://speed.cloudflare.com/__down?bytes=10485760',
      fileName: 'test_10mb_$ts.bin',
      preferences: _preferences,
    );
  }

  Future<void> _startBatchDownload() async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    await _downloader.downloadMultipleFiles(
      items: [
        DownloadRequestItem(
          url: 'https://speed.cloudflare.com/__down?bytes=5242880',
          fileName: 'batch_5mb_$ts.bin',
        ),
        DownloadRequestItem(
          url: 'https://speed.cloudflare.com/__down?bytes=10485760',
          fileName: 'batch_10mb_$ts.bin',
        ),
        DownloadRequestItem(
          url: 'https://codeload.github.com/Anandhakrishnan-CodeBlock/downloader_flutter/zip/refs/heads/main',
          fileName: 'repo_$ts.zip',
        ),
      ],
      preferences: _preferences,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Downloader Plugin Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    SwitchListTile(
                      dense: true,
                      title: const Text('Immediate Download'),
                      value: _preferences.isImmediate,
                      onChanged: (v) => setState(
                            () => _preferences = _preferences.copyWith(isImmediate: v),
                      ),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: const Text('Wi-Fi Only'),
                      value: _preferences.isWifiOnly,
                      onChanged: (v) => setState(
                            () => _preferences = _preferences.copyWith(isWifiOnly: v),
                      ),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: const Text('Power Saving Support'),
                      value: _preferences.isPowerSavingEnabled,
                      onChanged: (v) => setState(
                            () => _preferences =
                            _preferences.copyWith(isPowerSavingEnabled: v),
                      ),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: const Text('One By One (Sequential)'),
                      value: _preferences.isOneByOne,
                      onChanged: (v) => setState(
                            () => _preferences = _preferences.copyWith(isOneByOne: v),
                      ),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: const Text('Show Android Toasts'),
                      value: _preferences.showToastAndroid,
                      onChanged: (v) => setState(
                            () => _preferences =
                            _preferences.copyWith(showToastAndroid: v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startSingleDownload,
                    child: const Text('Single Download'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _startBatchDownload,
                    child: const Text('Batch (3 Files)'),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: StreamBuilder<List<DownloadTask>>(
                stream: _downloader.watchDownloads(),
                builder: (context, snapshot) {
                  final tasks = snapshot.data ?? const [];
                  if (tasks.isEmpty) {
                    return const Center(child: Text('No downloads yet'));
                  }
                  return ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _DownloadTaskTile(
                        task: task,
                        onPause: () => _downloader.pauseDownload(task.id),
                        onResume: () => _downloader.resumeDownload(task.id),
                        onCancel: () => _downloader.cancelDownload(task.id),
                        onDelete: () => _downloader.deleteDownload(task.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadTaskTile extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _DownloadTaskTile({
    required this.task,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIndeterminate =
        task.status == DownloadStatus.running && task.totalBytes <= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  task.status.name.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: isIndeterminate
                  ? null
                  : (task.percentage / 100.0).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 6),
            Text(
              '${_formatBytes(task.downloadedBytes)} / '
                  '${task.totalBytes > 0 ? _formatBytes(task.totalBytes) : "Unknown"} '
                  '(${task.percentage.toInt()}%)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (task.errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                task.errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: (task.status == DownloadStatus.running ||
                      task.status == DownloadStatus.queued)
                      ? onPause
                      : null,
                  child: const Text('Pause'),
                ),
                OutlinedButton(
                  onPressed: (task.status == DownloadStatus.paused ||
                      task.status == DownloadStatus.failed ||
                      task.status == DownloadStatus.cancelled)
                      ? onResume
                      : null,
                  child: const Text('Continue'),
                ),
                OutlinedButton(
                  onPressed: (task.status == DownloadStatus.running ||
                      task.status == DownloadStatus.queued ||
                      task.status == DownloadStatus.paused)
                      ? onCancel
                      : null,
                  child: const Text('Stop'),
                ),
                TextButton(
                  onPressed: onDelete,
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const kb = 1024.0;
    const mb = kb * 1024.0;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}