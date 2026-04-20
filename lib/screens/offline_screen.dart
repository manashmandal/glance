import 'package:flutter/material.dart';
import '../data/api_diagnostics.dart';
import '../theme/family_palette.dart';
import '../widgets/family/offline/bvg_status_card.dart';
import '../widgets/family/offline/diagnostics_list.dart';
import '../widgets/family/offline/offline_banner.dart';
import '../widgets/family/offline/offline_top_strip.dart';
import '../widgets/family/offline/stale_hero.dart';

/// Dashboard replacement shown when BVG is degraded. Surfaces the
/// last-known-good hero (dimmed), recent API attempts, and a simplified
/// status read. Pure — all inputs are computed by the caller.
class OfflineScreen extends StatelessWidget {
  final String city;
  final String stationName;
  final DateTime now;
  final Duration silentFor;
  final DateTime? lastSeenAt;
  final int countdownMinutes;
  final String destination;
  final String lineCode;
  final List<ApiAttempt> attempts;
  final BvgStatus status;
  final List<bool> uptime;
  final VoidCallback onRetry;

  const OfflineScreen({
    super.key,
    required this.city,
    required this.stationName,
    required this.now,
    required this.silentFor,
    required this.lastSeenAt,
    required this.countdownMinutes,
    required this.destination,
    required this.lineCode,
    required this.attempts,
    required this.status,
    required this.uptime,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FamilyPalette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OfflineTopStrip(
                city: city,
                stationName: stationName,
                now: now,
              ),
              const SizedBox(height: 28),
              OfflineBanner(silentFor: silentFor, onRetry: onRetry),
              const SizedBox(height: 24),
              StaleHero(
                lastSeenAt: lastSeenAt,
                countdownMinutes: countdownMinutes,
                destination: destination,
                lineCode: lineCode,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: DiagnosticsList(attempts: attempts),
                    ),
                    const SizedBox(width: 56),
                    Expanded(
                      flex: 4,
                      child: BvgStatusCard(status: status, uptime: uptime),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
