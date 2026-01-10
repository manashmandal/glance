import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../models/weather_action.dart';
import '../services/weather_ai_service.dart';
import '../services/theme_service.dart';

class WeatherActionWidget extends StatefulWidget {
  final double scaleFactor;

  const WeatherActionWidget({
    super.key,
    this.scaleFactor = 1.0,
  });

  @override
  State<WeatherActionWidget> createState() => WeatherActionWidgetState();
}

class WeatherActionWidgetState extends State<WeatherActionWidget> {
  WeatherAction? _action;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Action will be generated when weather data is provided
  }

  /// Generate action from weather data (called by parent)
  Future<void> generateAction(WeatherData weather) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final action = await WeatherAiService.generateAction(weather);
      if (mounted) {
        setState(() {
          _action = action;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  IconData _getIconForAction(String? iconName) {
    switch (iconName) {
      case 'umbrella': return Icons.umbrella;
      case 'cold': return Icons.ac_unit;
      case 'hot': return Icons.wb_sunny;
      case 'snow': return Icons.snowing;
      case 'storm': return Icons.thunderstorm;
      case 'wind': return Icons.air;
      case 'fog': return Icons.foggy;
      case 'sun': return Icons.wb_sunny;
      default: return Icons.tips_and_updates;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseFontSize = 16.0 * widget.scaleFactor;

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? null : Border.all(color: context.borderColor),
      ),
      child: _isLoading
          ? _buildLoadingState(baseFontSize)
          : _error != null
              ? _buildErrorState(baseFontSize)
              : _buildActionState(baseFontSize, isDark),
    );
  }

  Widget _buildLoadingState(double baseFontSize) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24 * widget.scaleFactor,
            height: 24 * widget.scaleFactor,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.textSecondary,
            ),
          ),
          SizedBox(height: 8 * widget.scaleFactor),
          Text(
            'Generating tip...',
            style: TextStyle(
              fontSize: baseFontSize * 0.75,
              color: context.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(double baseFontSize) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16 * widget.scaleFactor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 32 * widget.scaleFactor,
              color: context.textTertiary,
            ),
            SizedBox(height: 8 * widget.scaleFactor),
            Text(
              'Could not generate tip',
              style: TextStyle(
                fontSize: baseFontSize * 0.75,
                color: context.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionState(double baseFontSize, bool isDark) {
    final action = _action!;
    final isAi = action.source == WeatherActionSource.aiGenerated;

    return Padding(
      padding: EdgeInsets.all(16 * widget.scaleFactor),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 56 * widget.scaleFactor,
            height: 56 * widget.scaleFactor,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForAction(action.icon),
              size: 28 * widget.scaleFactor,
              color: context.textPrimary,
            ),
          ),
          SizedBox(height: 12 * widget.scaleFactor),
          // Action text
          Text(
            action.action,
            style: TextStyle(
              fontSize: baseFontSize,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8 * widget.scaleFactor),
          // Source indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isAi ? Icons.auto_awesome : Icons.psychology_alt,
                size: 12 * widget.scaleFactor,
                color: context.textTertiary,
              ),
              SizedBox(width: 4 * widget.scaleFactor),
              Text(
                isAi ? 'AI Suggestion' : 'Weather Tip',
                style: TextStyle(
                  fontSize: baseFontSize * 0.65,
                  color: context.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
