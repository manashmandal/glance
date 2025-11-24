import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../models/weather_data.dart';
import '../services/weather_service.dart';

class WeatherWidget extends StatefulWidget {
  final double scaleFactor;

  const WeatherWidget({
    super.key,
    this.scaleFactor = 1.0,
  });

  @override
  State<WeatherWidget> createState() => WeatherWidgetState();
}

class WeatherWidgetState extends State<WeatherWidget> {
  WeatherData? _weather;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    if (!mounted) return;
    // Only show loading if we don't have data yet
    if (_weather == null) {
      setState(() => _isLoading = true);
    }

    try {
      final weather = await WeatherService.getWeather();
      if (mounted) {
        setState(() {
          _weather = weather;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading weather: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: 0.3),
            const Color(0xFFF59E0B).withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF252931).withValues(alpha: 0.5),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (_isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (_weather == null) {
                  return const Center(
                    child: Text(
                      'Weather Unavailable',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final iconSize = constraints.maxHeight > 250
                    ? 100.0
                    : constraints.maxHeight * 0.35;
                final tempFontSize = (constraints.maxHeight > 250
                        ? 32.0
                        : constraints.maxHeight * 0.12) *
                    widget.scaleFactor;
                final descFontSize = (constraints.maxHeight > 250
                        ? 18.0
                        : constraints.maxHeight * 0.07) *
                    widget.scaleFactor;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF3B82F6).withValues(alpha: 0.8),
                            const Color(0xFFF59E0B).withValues(alpha: 0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            right: iconSize * 0.15,
                            top: iconSize * 0.15,
                            child: Icon(
                              Icons.wb_sunny,
                              size: iconSize * 0.4,
                              color: Colors.orange.shade300,
                            ),
                          ),
                          Positioned(
                            left: iconSize * 0.1,
                            bottom: iconSize * 0.1,
                            child: Icon(
                              Icons.cloud,
                              size: iconSize * 0.5,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.08),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Berlin, ${_weather!.temperature.round()}°C',
                        style: TextStyle(
                          fontSize: tempFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.03),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _weather!.weatherDescription,
                        style: TextStyle(
                          fontSize: descFontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'H: ${_weather!.maxTemp.round()}° L: ${_weather!.minTemp.round()}°',
                        style: TextStyle(
                          fontSize: descFontSize * 0.9,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
