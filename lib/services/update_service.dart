import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String latestVersion;
  final int latestBuildNumber;
  final String releaseNotes;
  final String downloadUrl;

  UpdateInfo({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}

class UpdateService {
  static const String repoOwner = 'yunlungp';
  static const String repoName = 'ash';

  /// 檢查 GitHub 是否有更新版本
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github.v3+json',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);
      final tagName = data['tag_name'] as String? ?? ''; // 如 "v1.0.0+3" 或 "1.0.0+3"
      final body = data['body'] as String? ?? '更新內容優化與 Bug 修復。';

      // 解析遠端版本與 build number
      int remoteBuildNumber = 0;
      String remoteVersionName = tagName;

      final plusIndex = tagName.indexOf('+');
      if (plusIndex != -1) {
        remoteVersionName = tagName.substring(0, plusIndex);
        remoteBuildNumber = int.tryParse(tagName.substring(plusIndex + 1)) ?? 0;
      } else {
        // 若 tag 沒有 + 號，嘗試從 assets 或 release 標題中獲取
        final match = RegExp(r'(\d+)\+(\d+)').firstMatch(tagName);
        if (match != null) {
          remoteBuildNumber = int.tryParse(match.group(2)!) ?? 0;
        }
      }

      // 尋找 APK 下載連結
      String apkUrl = '';
      final assets = data['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String? ?? '';
          break;
        }
      }

      // 如果有 APK 且 遠端 buildNumber 大於 當前 buildNumber
      if (remoteBuildNumber > currentBuildNumber && apkUrl.isNotEmpty) {
        return UpdateInfo(
          latestVersion: remoteVersionName.replaceAll('v', ''),
          latestBuildNumber: remoteBuildNumber,
          releaseNotes: body,
          downloadUrl: apkUrl,
        );
      }
    } catch (_) {
      // 網路異常或超時忽略，不影響正常進入遊戲
    }
    return null;
  }

  /// 彈出更新確認對話框並支援下載安裝
  static void promptUpdate(BuildContext context, UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _UpdateDialog(updateInfo: updateInfo),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const _UpdateDialog({required this.updateInfo});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';

  Future<void> _startDownloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _statusText = '準備下載...';
    });

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.updateInfo.downloadUrl));
      final response = await client.send(request);

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/app-update-${widget.updateInfo.latestBuildNumber}.apk';
      final file = File(filePath);

      final sink = file.openWrite();

      await response.stream.listen((chunk) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0) {
          setState(() {
            _progress = receivedBytes / totalBytes;
            _statusText = '下載進度: ${(_progress * 100).toStringAsFixed(1)}%';
          });
        } else {
          setState(() {
            _statusText = '已下載 ${(receivedBytes / 1024 / 1024).toStringAsFixed(1)} MB';
          });
        }
      }).asFuture();

      await sink.flush();
      await sink.close();

      setState(() {
        _statusText = '下載完成，正在開啟安裝程序...';
      });

      // 喚起 Android 系統安裝 APK
      final result = await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
      if (result.type != ResultType.done) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _statusText = '開啟安裝失敗: ${result.message}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = '下載失敗，請檢查網路連線後重試';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1B2330),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF3B4860), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 標題
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.system_update, color: Colors.amberAccent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '發現新版本！',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '版本 v${widget.updateInfo.latestVersion} (Build ${widget.updateInfo.latestBuildNumber})',
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 更新說明
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF141923),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2C394C)),
                ),
                child: Text(
                  widget.updateInfo.releaseNotes.trim().isEmpty
                      ? '包含性能提升與遊戲性優化。'
                      : widget.updateInfo.releaseNotes,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              if (_isDownloading || _statusText.isNotEmpty) ...[
                const SizedBox(height: 14),
                if (_isDownloading)
                  LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                const SizedBox(height: 6),
                Text(
                  _statusText,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 16),

              // 底部按鈕
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isDownloading)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('稍後再說', style: TextStyle(color: Colors.white60)),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent.shade700,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: _isDownloading ? null : _startDownloadAndInstall,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.download, size: 18),
                    label: Text(
                      _isDownloading ? '下載中...' : '立即更新',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
