import 'package:flutter_test/flutter_test.dart';
import 'package:glance/models/weather_data.dart';

void main() {
  group('WeatherData', () {
    group('basic construction', () {
      test('creates with required parameters', () {
        final weather = WeatherData(
          temperature: 20.0,
          weatherCode: 0,
          maxTemp: 25.0,
          minTemp: 15.0,
        );

        expect(weather.temperature, equals(20.0));
        expect(weather.weatherCode, equals(0));
        expect(weather.maxTemp, equals(25.0));
        expect(weather.minTemp, equals(15.0));
      });

      test('creates with optional AI context parameters', () {
        final weather = WeatherData(
          temperature: 20.0,
          weatherCode: 0,
          maxTemp: 25.0,
          minTemp: 15.0,
          precipitationProbability: 30.0,
          windSpeed: 15.0,
          humidity: 65.0,
        );

        expect(weather.precipitationProbability, equals(30.0));
        expect(weather.windSpeed, equals(15.0));
        expect(weather.humidity, equals(65.0));
      });

      test('optional parameters default to null', () {
        final weather = WeatherData(
          temperature: 20.0,
          weatherCode: 0,
          maxTemp: 25.0,
          minTemp: 15.0,
        );

        expect(weather.precipitationProbability, isNull);
        expect(weather.windSpeed, isNull);
        expect(weather.humidity, isNull);
        expect(weather.hourlyForecast, isNull);
      });
    });

    group('fromJson', () {
      test('parses basic weather data', () {
        final json = {
          'current': {
            'temperature_2m': 22.5,
            'weather_code': 3,
          },
          'daily': {
            'temperature_2m_max': [28.0],
            'temperature_2m_min': [18.0],
          },
        };

        final weather = WeatherData.fromJson(json);

        expect(weather.temperature, equals(22.5));
        expect(weather.weatherCode, equals(3));
        expect(weather.maxTemp, equals(28.0));
        expect(weather.minTemp, equals(18.0));
      });

      test('parses AI context fields', () {
        final json = {
          'current': {
            'temperature_2m': 22.5,
            'weather_code': 3,
            'precipitation_probability': 40.0,
            'wind_speed_10m': 12.5,
            'relative_humidity_2m': 70.0,
          },
          'daily': {
            'temperature_2m_max': [28.0],
            'temperature_2m_min': [18.0],
          },
        };

        final weather = WeatherData.fromJson(json);

        expect(weather.precipitationProbability, equals(40.0));
        expect(weather.windSpeed, equals(12.5));
        expect(weather.humidity, equals(70.0));
      });

      test('parses hourly forecast', () {
        final now = DateTime.now();
        final json = {
          'current': {
            'temperature_2m': 22.5,
            'weather_code': 3,
          },
          'daily': {
            'temperature_2m_max': [28.0],
            'temperature_2m_min': [18.0],
          },
          'hourly': {
            'time': [
              now.toIso8601String(),
              now.add(const Duration(hours: 1)).toIso8601String(),
              now.add(const Duration(hours: 2)).toIso8601String(),
            ],
            'temperature_2m': [22.0, 23.0, 24.0],
            'weather_code': [0, 1, 3],
            'precipitation_probability': [10.0, 20.0, 30.0],
          },
        };

        final weather = WeatherData.fromJson(json);

        expect(weather.hourlyForecast, isNotNull);
        expect(weather.hourlyForecast!.length, equals(3));
        expect(weather.hourlyForecast![0].temperature, equals(22.0));
        expect(weather.hourlyForecast![1].weatherCode, equals(1));
        expect(weather.hourlyForecast![2].precipitationProbability, equals(30.0));
      });

      test('limits hourly forecast to 12 entries', () {
        final now = DateTime.now();
        final times = List.generate(
          24,
          (i) => now.add(Duration(hours: i)).toIso8601String(),
        );
        final temps = List.generate(24, (i) => 20.0 + i);
        final codes = List.generate(24, (i) => i % 10);

        final json = {
          'current': {
            'temperature_2m': 22.5,
            'weather_code': 3,
          },
          'daily': {
            'temperature_2m_max': [28.0],
            'temperature_2m_min': [18.0],
          },
          'hourly': {
            'time': times,
            'temperature_2m': temps,
            'weather_code': codes,
          },
        };

        final weather = WeatherData.fromJson(json);

        expect(weather.hourlyForecast!.length, equals(12));
      });

      test('handles missing optional fields', () {
        final json = {
          'current': {
            'temperature_2m': 22.5,
            'weather_code': 3,
          },
          'daily': {
            'temperature_2m_max': [28.0],
            'temperature_2m_min': [18.0],
          },
        };

        final weather = WeatherData.fromJson(json);

        expect(weather.precipitationProbability, isNull);
        expect(weather.windSpeed, isNull);
        expect(weather.humidity, isNull);
        expect(weather.hourlyForecast, isNull);
      });

      test('handles null values in json', () {
        final json = {
          'current': {
            'temperature_2m': null,
            'weather_code': null,
          },
          'daily': {
            'temperature_2m_max': [null],
            'temperature_2m_min': [null],
          },
        };

        final weather = WeatherData.fromJson(json);

        expect(weather.temperature, equals(0.0));
        expect(weather.weatherCode, equals(0));
        expect(weather.maxTemp, equals(0.0));
        expect(weather.minTemp, equals(0.0));
      });
    });

    group('weatherDescription', () {
      test('returns Clear sky for code 0', () {
        final weather = WeatherData(
          temperature: 20.0,
          weatherCode: 0,
          maxTemp: 25.0,
          minTemp: 15.0,
        );

        expect(weather.weatherDescription, equals('Clear sky'));
      });

      test('returns Partly cloudy for codes 1-3', () {
        for (final code in [1, 2, 3]) {
          final weather = WeatherData(
            temperature: 20.0,
            weatherCode: code,
            maxTemp: 25.0,
            minTemp: 15.0,
          );

          expect(weather.weatherDescription, equals('Partly cloudy'));
        }
      });

      test('returns Foggy for codes 45, 48', () {
        for (final code in [45, 48]) {
          final weather = WeatherData(
            temperature: 20.0,
            weatherCode: code,
            maxTemp: 25.0,
            minTemp: 15.0,
          );

          expect(weather.weatherDescription, equals('Foggy'));
        }
      });

      test('returns Drizzle for codes 51, 53, 55', () {
        for (final code in [51, 53, 55]) {
          final weather = WeatherData(
            temperature: 20.0,
            weatherCode: code,
            maxTemp: 25.0,
            minTemp: 15.0,
          );

          expect(weather.weatherDescription, equals('Drizzle'));
        }
      });

      test('returns Rain for codes 61, 63, 65', () {
        for (final code in [61, 63, 65]) {
          final weather = WeatherData(
            temperature: 20.0,
            weatherCode: code,
            maxTemp: 25.0,
            minTemp: 15.0,
          );

          expect(weather.weatherDescription, equals('Rain'));
        }
      });

      test('returns Snow for codes 71, 73, 75', () {
        for (final code in [71, 73, 75]) {
          final weather = WeatherData(
            temperature: 20.0,
            weatherCode: code,
            maxTemp: 25.0,
            minTemp: 15.0,
          );

          expect(weather.weatherDescription, equals('Snow'));
        }
      });

      test('returns Thunderstorm for codes 95, 96, 99', () {
        for (final code in [95, 96, 99]) {
          final weather = WeatherData(
            temperature: 20.0,
            weatherCode: code,
            maxTemp: 25.0,
            minTemp: 15.0,
          );

          expect(weather.weatherDescription, equals('Thunderstorm'));
        }
      });

      test('returns Unknown for unrecognized codes', () {
        final weather = WeatherData(
          temperature: 20.0,
          weatherCode: 999,
          maxTemp: 25.0,
          minTemp: 15.0,
        );

        expect(weather.weatherDescription, equals('Unknown'));
      });
    });

    group('toAiContextString', () {
      test('includes basic weather info', () {
        final weather = WeatherData(
          temperature: 22.0,
          weatherCode: 0,
          maxTemp: 28.0,
          minTemp: 18.0,
        );

        final context = weather.toAiContextString();

        expect(context, contains('Temperature: 22°C'));
        expect(context, contains('Clear sky'));
        expect(context, contains('28°C / 18°C'));
      });

      test('includes precipitation probability when available', () {
        final weather = WeatherData(
          temperature: 22.0,
          weatherCode: 0,
          maxTemp: 28.0,
          minTemp: 18.0,
          precipitationProbability: 45.0,
        );

        final context = weather.toAiContextString();

        expect(context, contains('Precipitation chance: 45%'));
      });

      test('includes wind speed when available', () {
        final weather = WeatherData(
          temperature: 22.0,
          weatherCode: 0,
          maxTemp: 28.0,
          minTemp: 18.0,
          windSpeed: 25.0,
        );

        final context = weather.toAiContextString();

        expect(context, contains('Wind speed: 25 km/h'));
      });

      test('includes humidity when available', () {
        final weather = WeatherData(
          temperature: 22.0,
          weatherCode: 0,
          maxTemp: 28.0,
          minTemp: 18.0,
          humidity: 70.0,
        );

        final context = weather.toAiContextString();

        expect(context, contains('Humidity: 70%'));
      });

      test('includes hourly forecast when available', () {
        final now = DateTime(2024, 1, 15, 14, 0);
        final weather = WeatherData(
          temperature: 22.0,
          weatherCode: 0,
          maxTemp: 28.0,
          minTemp: 18.0,
          hourlyForecast: [
            HourlyForecast(
              time: now,
              temperature: 22.0,
              weatherCode: 0,
            ),
            HourlyForecast(
              time: now.add(const Duration(hours: 1)),
              temperature: 23.0,
              weatherCode: 1,
            ),
          ],
        );

        final context = weather.toAiContextString();

        expect(context, contains('Next few hours'));
        expect(context, contains('14:00'));
        expect(context, contains('22°C'));
      });

      test('limits hourly forecast in context to 6 entries', () {
        final now = DateTime(2024, 1, 15, 14, 0);
        final weather = WeatherData(
          temperature: 22.0,
          weatherCode: 0,
          maxTemp: 28.0,
          minTemp: 18.0,
          hourlyForecast: List.generate(
            12,
            (i) => HourlyForecast(
              time: now.add(Duration(hours: i)),
              temperature: 20.0 + i,
              weatherCode: 0,
            ),
          ),
        );

        final context = weather.toAiContextString();
        final hourLines = context.split('\n').where(
              (line) => line.contains(':00:'),
            );

        expect(hourLines.length, equals(6));
      });

      test('excludes missing optional fields', () {
        final weather = WeatherData(
          temperature: 22.0,
          weatherCode: 0,
          maxTemp: 28.0,
          minTemp: 18.0,
        );

        final context = weather.toAiContextString();

        expect(context, isNot(contains('Precipitation')));
        expect(context, isNot(contains('Wind')));
        expect(context, isNot(contains('Humidity')));
        expect(context, isNot(contains('Next few hours')));
      });
    });
  });

  group('HourlyForecast', () {
    test('creates with required parameters', () {
      final time = DateTime(2024, 1, 15, 14, 0);
      final forecast = HourlyForecast(
        time: time,
        temperature: 22.0,
        weatherCode: 3,
      );

      expect(forecast.time, equals(time));
      expect(forecast.temperature, equals(22.0));
      expect(forecast.weatherCode, equals(3));
      expect(forecast.precipitationProbability, isNull);
    });

    test('creates with precipitation probability', () {
      final forecast = HourlyForecast(
        time: DateTime.now(),
        temperature: 22.0,
        weatherCode: 61,
        precipitationProbability: 80.0,
      );

      expect(forecast.precipitationProbability, equals(80.0));
    });

    group('weatherCodeDescription', () {
      test('returns Clear for code 0', () {
        final forecast = HourlyForecast(
          time: DateTime.now(),
          temperature: 22.0,
          weatherCode: 0,
        );

        expect(forecast.weatherCodeDescription, equals('Clear'));
      });

      test('returns Cloudy for codes 1-3', () {
        for (final code in [1, 2, 3]) {
          final forecast = HourlyForecast(
            time: DateTime.now(),
            temperature: 22.0,
            weatherCode: code,
          );

          expect(forecast.weatherCodeDescription, equals('Cloudy'));
        }
      });

      test('returns Fog for codes 45, 48', () {
        for (final code in [45, 48]) {
          final forecast = HourlyForecast(
            time: DateTime.now(),
            temperature: 22.0,
            weatherCode: code,
          );

          expect(forecast.weatherCodeDescription, equals('Fog'));
        }
      });

      test('returns Drizzle for codes 51, 53, 55', () {
        for (final code in [51, 53, 55]) {
          final forecast = HourlyForecast(
            time: DateTime.now(),
            temperature: 22.0,
            weatherCode: code,
          );

          expect(forecast.weatherCodeDescription, equals('Drizzle'));
        }
      });

      test('returns Rain for codes 61, 63, 65', () {
        for (final code in [61, 63, 65]) {
          final forecast = HourlyForecast(
            time: DateTime.now(),
            temperature: 22.0,
            weatherCode: code,
          );

          expect(forecast.weatherCodeDescription, equals('Rain'));
        }
      });

      test('returns Snow for codes 71, 73, 75', () {
        for (final code in [71, 73, 75]) {
          final forecast = HourlyForecast(
            time: DateTime.now(),
            temperature: 22.0,
            weatherCode: code,
          );

          expect(forecast.weatherCodeDescription, equals('Snow'));
        }
      });

      test('returns Thunderstorm for codes 95, 96, 99', () {
        for (final code in [95, 96, 99]) {
          final forecast = HourlyForecast(
            time: DateTime.now(),
            temperature: 22.0,
            weatherCode: code,
          );

          expect(forecast.weatherCodeDescription, equals('Thunderstorm'));
        }
      });

      test('returns Unknown for unrecognized codes', () {
        final forecast = HourlyForecast(
          time: DateTime.now(),
          temperature: 22.0,
          weatherCode: 999,
        );

        expect(forecast.weatherCodeDescription, equals('Unknown'));
      });
    });
  });
}
