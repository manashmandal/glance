import 'dart:convert';
import 'dart:io';

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

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final bool updateAvailable;
  final String releaseName;
  final String releaseNotes;
  final DateTime? publishedAt;

  const UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.updateAvailable,
    required this.releaseName,
    required this.releaseNotes,
    required this.publishedAt,
  });
}

class UpdateService {
  static const _repo = 'manashmandal/glance';
  static const _latestUrl = 'https://api.github.com/repos/$_repo/releases/latest';
  static const _releasesUrl = 'https://api.github.com/repos/$_repo/releases';

  static Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    final body = await _getJson(_latestUrl);
    if (body is! Map<String, dynamic>) return null;

    final tag = body['tag_name'] as String?;
    final htmlUrl = body['html_url'] as String?;
    if (tag == null || htmlUrl == null) return null;

    final latestVersion = tag.startsWith('v') ? tag.substring(1) : tag;
    final publishedRaw = body['published_at'] as String?;
    final name = (body['name'] as String?)?.trim();
    return UpdateInfo(
      latestVersion: latestVersion,
      downloadUrl: htmlUrl,
      updateAvailable: isNewerVersion(latestVersion, currentVersion),
      releaseName: (name != null && name.isNotEmpty) ? name : tag,
      releaseNotes: (body['body'] as String? ?? '').trim(),
      publishedAt:
          publishedRaw == null ? null : DateTime.tryParse(publishedRaw),
    );
  }

  static Future<List<ReleaseEntry>> fetchRecentReleases({int count = 5}) async {
    final body = await _getJson('$_releasesUrl?per_page=$count');
    if (body is! List) return const [];
    return body
        .whereType<Map<String, dynamic>>()
        .map(ReleaseEntry.fromJson)
        .where((r) => r.tag.isNotEmpty)
        .toList(growable: false);
  }

  static Future<Object?> _getJson(String url) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('Accept', 'application/vnd.github+json');
      request.headers.set('User-Agent', 'glance-app');
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
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
