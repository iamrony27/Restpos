import 'dart:convert';
import 'dart:io';
import '../core/constants/app_version.dart';

class UpdateInfo {
  final bool isUpdateAvailable;
  final String currentVersion;
  final String latestVersion;
  final String? releaseNotes;
  final String? downloadUrl;
  final String? publishedAt;
  final String repoUrl;
  final String statusMessage;

  const UpdateInfo({
    required this.isUpdateAvailable,
    required this.currentVersion,
    required this.latestVersion,
    this.releaseNotes,
    this.downloadUrl,
    this.publishedAt,
    required this.repoUrl,
    required this.statusMessage,
  });
}

class GitHubUpdateService {
  static const String currentVersion = AppVersion.tag;
  static const String repoOwner = 'iamrony27';
  static const String repoName = 'Restpos';
  static const String repoUrl = 'https://github.com/iamrony27/Restpos';
  static const String apiUrl = 'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  /// Checks GitHub for the latest release
  static Future<UpdateInfo> checkForUpdate() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(Uri.parse(apiUrl));
      request.headers.set('User-Agent', 'Restpos-Flutter-App');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;

        final tagName = data['tag_name']?.toString() ?? currentVersion;
        final htmlUrl = data['html_url']?.toString() ?? repoUrl;
        final notes = data['body']?.toString() ?? 'No release notes provided.';
        final published = data['published_at']?.toString();

        // Find APK asset if available
        String downloadUrl = htmlUrl;
        if (data['assets'] is List && (data['assets'] as List).isNotEmpty) {
          final assets = data['assets'] as List;
          final apkAsset = assets.firstWhere(
            (a) => a['name']?.toString().endsWith('.apk') == true,
            orElse: () => null,
          );
          if (apkAsset != null && apkAsset['browser_download_url'] != null) {
            downloadUrl = apkAsset['browser_download_url'].toString();
          }
        }

        final isNewer = _compareVersions(tagName, currentVersion) > 0;

        return UpdateInfo(
          isUpdateAvailable: isNewer,
          currentVersion: currentVersion,
          latestVersion: tagName.isNotEmpty ? tagName : currentVersion,
          releaseNotes: isNewer ? notes : null,
          downloadUrl: downloadUrl,
          publishedAt: published,
          repoUrl: repoUrl,
          statusMessage: isNewer
              ? 'A newer version ($tagName) is available on GitHub!'
              : 'You are on the latest version ($currentVersion)! Everything is up to date.',
        );
      } else if (response.statusCode == 404) {
        // No release tag created yet on GitHub repo
        return const UpdateInfo(
          isUpdateAvailable: false,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          repoUrl: repoUrl,
          statusMessage: 'You are on the latest version ($currentVersion)! Everything is up to date.',
        );
      } else {
        return const UpdateInfo(
          isUpdateAvailable: false,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          repoUrl: repoUrl,
          statusMessage: 'You are running the official version ($currentVersion).',
        );
      }
    } catch (e) {
      return const UpdateInfo(
        isUpdateAvailable: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        repoUrl: repoUrl,
        statusMessage: 'Offline or network unavailable. Current version: $currentVersion.',
      );
    }
  }

  /// Returns > 0 if v1 > v2, 0 if equal, < 0 if v1 < v2
  static int _compareVersions(String v1, String v2) {
    try {
      final clean1 = v1.replaceAll(RegExp(r'[^0-9.]'), '');
      final clean2 = v2.replaceAll(RegExp(r'[^0-9.]'), '');
      final p1 = clean1.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      final p2 = clean2.split('.').map((s) => int.tryParse(s) ?? 0).toList();

      final maxLen = p1.length > p2.length ? p1.length : p2.length;
      for (int i = 0; i < maxLen; i++) {
        final val1 = i < p1.length ? p1[i] : 0;
        final val2 = i < p2.length ? p2[i] : 0;
        if (val1 != val2) return val1.compareTo(val2);
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
