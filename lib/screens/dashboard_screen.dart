import 'package:flutter/material.dart';
import '../widgets/clock_widget.dart';
import '../widgets/weather_widget.dart';
import '../widgets/train_departures_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D23),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Top row with clock and weather
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    // Clock module
                    Expanded(
                      flex: 3,
                      child: ClockWidget(),
                    ),
                    const SizedBox(width: 24),
                    // Weather module
                    Expanded(
                      flex: 2,
                      child: WeatherWidget(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Bottom section with train departures
              Expanded(
                flex: 3,
                child: TrainDeparturesWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
