import 'dart:collection';

import 'package:flutter/foundation.dart';

enum ApiSource { bvg, weather, update, other }

/// BVG feed health grades derived from [ApiDiagnostics].
///
/// - [operational] — last BVG success is within the freshness window.
/// - [degraded] — we haven't seen a success in a few minutes but the
///   app is still trying.
/// - [outage] — prolonged silence; unlikely to self-recover soon.
enum BvgStatus { operational, degraded, outage }

class ApiAttempt {
  final String endpoint;
  final String statusLabel;
  final bool success;
  final DateTime at;
  final ApiSource source;

  const ApiAttempt({
    required this.endpoint,
    required this.statusLabel,
    required this.success,
    required this.at,
    required this.source,
  });
}

/// In-memory ring buffer of recent HTTP attempts. Powers the offline screen's
/// "What we tried" list and its derived status signal. Not persisted.
class ApiDiagnostics {
  ApiDiagnostics._();

  static const int _maxAttempts = 12;
  static const Duration _staleThreshold = Duration(minutes: 4);
  static const Duration _outageThreshold = Duration(minutes: 15);

  static final Queue<ApiAttempt> _attempts = Queue<ApiAttempt>();
  static DateTime? _lastBvgSuccess;

  static void record(ApiAttempt attempt) {
    _attempts.addFirst(attempt);
    while (_attempts.length > _maxAttempts) {
      _attempts.removeLast();
    }
    if (attempt.success && attempt.source == ApiSource.bvg) {
      _lastBvgSuccess = attempt.at;
    }
  }

  static List<ApiAttempt> get recent => List.unmodifiable(_attempts);

  static DateTime? get lastBvgSuccess => _lastBvgSuccess;

  @visibleForTesting
  static void reset() {
    _attempts.clear();
    _lastBvgSuccess = null;
  }

  /// True when the last BVG success was more than [_staleThreshold] ago AND
  /// the most recent BVG attempt failed. Used to decide whether to show the
  /// offline screen.
  static bool get bvgDegraded {
    final lastBvg = _attempts.where((a) => a.source == ApiSource.bvg);
    if (lastBvg.isEmpty) return false;
    if (lastBvg.first.success) return false;
    final lastOk = _lastBvgSuccess;
    if (lastOk == null) return true;
    return DateTime.now().difference(lastOk) > _staleThreshold;
  }

  /// Duration since the most recent successful BVG call. Defaults to the
  /// stale threshold when we've never observed a success — callers can
  /// read "unknown" as "we should probably act like it's stale."
  static Duration get bvgSilentFor {
    final lastOk = _lastBvgSuccess;
    if (lastOk == null) return _staleThreshold;
    return DateTime.now().difference(lastOk);
  }

  /// Coarse health grade based on [bvgSilentFor] and the thresholds.
  static BvgStatus get bvgStatus {
    final silent = bvgSilentFor;
    if (silent > _outageThreshold) return BvgStatus.outage;
    if (silent > _staleThreshold) return BvgStatus.degraded;
    return BvgStatus.operational;
  }

  /// Most recent BVG-source attempts, newest first, capped at [length].
  static List<ApiAttempt> recentBvg({int length = 4}) => _attempts
      .where((a) => a.source == ApiSource.bvg)
      .take(length)
      .toList(growable: false);

  /// Rolling status (success/fail) for the last N BVG attempts, oldest first.
  /// Returns an all-true window when we haven't collected enough attempts yet.
  static List<bool> bvgUptimeWindow({int length = 7}) {
    final bvg =
        _attempts.where((a) => a.source == ApiSource.bvg).take(length).toList();
    final window = bvg.reversed.map((a) => a.success).toList(growable: true);
    while (window.length < length) {
      window.insert(0, true);
    }
    return List.unmodifiable(window);
  }
}
