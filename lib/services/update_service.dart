import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/api_diagnostics.dart';

class ReleaseEntry {
  final String tag;
  final String name;
  final DateTime? publishedAt;
  final String notes;
  final String htmlUrl;

  const ReleaseEntry({
    required this.tag,
    required this.name,
    required this.publishedAt,
    required this.notes,
    required this.htmlUrl,
  });

  factory ReleaseEntry.fromJson(Map<String, dynamic> json) {
    final tag = json['tag_name'] as String? ?? '';
    final publishedRaw = json['published_at'] as String?;
    return ReleaseEntry(
      tag: tag,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : tag,
      publishedAt:
          publishedRaw == null ? null : DateTime.tryParse(publishedRaw),
      notes: (json['body'] as String? ?? '').trim(),
      htmlUrl: json['html_url'] as String? ?? '',
    );
  }

  String get version => tag.startsWith('v') ? tag.substring(1) : tag;
}

/// Describes an available update. [UpdateService.checkForUpdate] returns
/// `null` when the app is already on the latest version or when the
/// lookup failed — so an instance of this class always means "there is
/// a newer version than the one currently running."
class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseName;
  final String releaseNotes;
  final DateTime? publishedAt;

  const UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseName,
    required this.releaseNotes,
    required this.publishedAt,
  });
}

class UpdateService {
  static const _repo = 'manashmandal/glance';
  static const _latestUrl =
      'https://api.github.com/repos/$_repo/releases/latest';
  static const _releasesUrl = 'https://api.github.com/repos/$_repo/releases';

  /// Returns an [UpdateInfo] if GitHub reports a newer version than the
  /// running one, or `null` when we're already on the latest release,
  /// when the response is malformed, or when the lookup fails.
  static Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    final body = await _fetchJson(_latestUrl);
    if (body is! Map<String, dynamic>) return null;

    final tag = body['tag_name'] as String?;
    final htmlUrl = body['html_url'] as String?;
    if (tag == null || htmlUrl == null) return null;

    final latestVersion = tag.startsWith('v') ? tag.substring(1) : tag;
    if (!isNewerVersion(latestVersion, currentVersion)) return null;

    final publishedRaw = body['published_at'] as String?;
    final name = (body['name'] as String?)?.trim();
    return UpdateInfo(
      latestVersion: latestVersion,
      downloadUrl: htmlUrl,
      releaseName: (name != null && name.isNotEmpty) ? name : tag,
      releaseNotes: (body['body'] as String? ?? '').trim(),
      publishedAt:
          publishedRaw == null ? null : DateTime.tryParse(publishedRaw),
    );
  }

  static Future<List<ReleaseEntry>> fetchRecentReleases({int count = 5}) async {
    final body = await _fetchJson('$_releasesUrl?per_page=$count');
    if (body is! List) return const [];
    return body
        .whereType<Map<String, dynamic>>()
        .map(ReleaseEntry.fromJson)
        .where((r) => r.tag.isNotEmpty)
        .toList(growable: false);
  }

  static const Duration _timeout = Duration(seconds: 10);

  static Future<Object?> _fetchJson(String url) async {
    final sw = Stopwatch()..start();
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url)).timeout(_timeout);
      request.headers.set('Accept', 'application/vnd.github+json');
      request.headers.set('User-Agent', 'glance-app');
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != 200) {
        sw.stop();
        _record(url, sw, success: false, code: response.statusCode);
        debugPrint('UpdateService GET $url -> ${response.statusCode}');
        return null;
      }
      final body =
          await response.transform(utf8.decoder).join().timeout(_timeout);
      sw.stop();
      _record(url, sw, success: true, code: 200);
      return jsonDecode(body);
    } catch (e) {
      sw.stop();
      _record(url, sw, success: false, error: e);
      debugPrint('UpdateService GET $url failed: $e');
      return null;
    } finally {
      client.close(force: false);
    }
  }

  static void _record(
    String url,
    Stopwatch sw, {
    required bool success,
    int? code,
    Object? error,
  }) {
    final d = sw.elapsed;
    String label;
    if (error != null) {
      label = error is TimeoutException
          ? 'timeout · ${d.inSeconds}s'
          : 'error · ${error.runtimeType}';
    } else if (code == 200) {
      final ms = d.inMilliseconds;
      label = ms >= 1000
          ? '200 · ${(ms / 1000).toStringAsFixed(1)}s'
          : '200 · ${ms}ms';
    } else {
      label = '${code ?? 'fail'} · ${d.inSeconds}s';
    }
    ApiDiagnostics.record(ApiAttempt(
      endpoint: _shortUrl(url),
      statusLabel: label,
      success: success,
      at: DateTime.now(),
      source: ApiSource.update,
    ));
  }

  static String _shortUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return '${uri.host}${uri.path}';
  }

  static bool isNewerVersion(String latest, String current) {
    final latestParts = _parseVersion(latest);
    final currentParts = _parseVersion(current);

    for (var i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static List<int> _parseVersion(String version) {
    final cleanVersion = version.split('+').first;
    final parts = cleanVersion.split('.');
    return [
      parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
    ];
  }
}
