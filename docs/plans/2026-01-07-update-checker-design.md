# Update Checker Feature Design

## Overview

Add automatic update checking to notify users when a new version of Glance is available on GitHub Releases.

## Requirements

- Check for updates on app startup and every 24 hours
- Show header icon when update available
- Tap icon opens GitHub releases page in browser
- Silent failure - don't show errors to users

## Architecture

### UpdateService

New service at `lib/services/update_service.dart`:

```dart
class UpdateService {
  static const _apiUrl = 'https://api.github.com/repos/manashmandal/glance/releases/latest';

  static Future<UpdateInfo?> checkForUpdate(String currentVersion);
}

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final bool updateAvailable;
}
```

**API Response:**
```json
{
  "tag_name": "v0.0.9",
  "html_url": "https://github.com/manashmandal/glance/releases/tag/v0.0.9"
}
```

**Version Comparison:**
- Strip leading "v" from tag_name
- Parse as semantic version (major.minor.patch)
- Compare numerically

### UI Integration

**Location:** Header row, after theme toggle, before refresh button

**States:**
- No update / checking / error: Icon hidden
- Update available: Show download icon with accent color

**Tap action:** Open `https://github.com/manashmandal/glance/releases/latest` via url_launcher

**Tooltip:** "Update available: vX.X.X - Click to download"

### Timer Logic

```dart
// In DashboardScreen
Timer? _updateCheckTimer;
bool _updateAvailable = false;
String? _latestVersion;
String? _downloadUrl;

@override
void initState() {
  super.initState();
  _checkForUpdates();  // Immediate check
  _updateCheckTimer = Timer.periodic(
    Duration(hours: 24),
    (_) => _checkForUpdates(),
  );
}
```

## Dependencies

**Add to pubspec.yaml:**
```yaml
dependencies:
  url_launcher: ^6.2.0
```

## Files Changed

| File | Change |
|------|--------|
| `lib/services/update_service.dart` | New - update check logic |
| `lib/screens/dashboard_screen.dart` | Add icon, state, timer |
| `pubspec.yaml` | Add url_launcher |

## Error Handling

- Network errors: Silent fail, don't show icon
- Parse errors: Silent fail, log to console
- API rate limits: Silent fail (60 req/hour for unauthenticated)
