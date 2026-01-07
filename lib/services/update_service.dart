import 'dart:convert';
import 'dart:io';

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final bool updateAvailable;

  const UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.updateAvailable,
  });
}

class UpdateService {
  static const _apiUrl =
      'https://api.github.com/repos/manashmandal/glance/releases/latest';

  static Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(_apiUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        return null;
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final json = jsonDecode(responseBody) as Map<String, dynamic>;

      final tagName = json['tag_name'] as String?;
      final htmlUrl = json['html_url'] as String?;

      if (tagName == null || htmlUrl == null) {
        return null;
      }

      final latestVersion =
          tagName.startsWith('v') ? tagName.substring(1) : tagName;
      final updateAvailable = isNewerVersion(latestVersion, currentVersion);

      return UpdateInfo(
        latestVersion: latestVersion,
        downloadUrl: htmlUrl,
        updateAvailable: updateAvailable,
      );
    } catch (e) {
      return null;
    }
  }

  static bool isNewerVersion(String latest, String current) {
    final latestParts = _parseVersion(latest);
    final currentParts = _parseVersion(current);

    for (var i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) {
        return true;
      }
      if (latestParts[i] < currentParts[i]) {
        return false;
      }
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
