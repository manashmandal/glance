# AI-Based Weather Actions Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the logo widget with AI-generated weather actions (e.g., "Take an umbrella", "Wear warm clothes") using on-device ML on Android tablets.

**Architecture:** Extend weather data with hourly forecasts, create a platform channel bridge to native Android ML Kit GenAI APIs (Gemini Nano), and build a new WeatherActionWidget that displays AI-generated suggestions. Settings toggle allows users to switch between logo and weather actions.

**Tech Stack:** Flutter (Dart), Android Native (Kotlin), ML Kit GenAI Summarization/Prompt API, Gemini Nano (on-device), Platform Channels

---

## Prerequisites & Device Requirements

**Important:** ML Kit GenAI APIs with Gemini Nano have device requirements:
- Android API level 26+ (Android 8.0 Oreo)
- Device with AICore system service (Pixel 6+, Samsung Galaxy S24+, and other supported devices)
- Not all Android tablets support Gemini Nano - the implementation includes graceful fallback

**Fallback Strategy:** If Gemini Nano is unavailable, use rule-based weather actions as a fallback.

---

## Task 1: Extend Weather Data Model

**Files:**
- Modify: `lib/models/weather_data.dart`

**Step 1: Read current weather_data.dart**

Review the existing implementation at `lib/models/weather_data.dart:1-57`

**Step 2: Add extended weather properties**

Add hourly forecast data and precipitation probability for AI context:

```dart
class WeatherData {
  final double temperature;
  final int weatherCode;
  final double maxTemp;
  final double minTemp;
  // New fields for AI context
  final double? precipitationProbability;
  final double? windSpeed;
  final double? humidity;
  final List<HourlyForecast>? hourlyForecast;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
    this.precipitationProbability,
    this.windSpeed,
    this.humidity,
    this.hourlyForecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final daily = json['daily'];
    final hourly = json['hourly'];

    List<HourlyForecast>? hourlyList;
    if (hourly != null) {
      final times = hourly['time'] as List?;
      final temps = hourly['temperature_2m'] as List?;
      final codes = hourly['weather_code'] as List?;
      final precip = hourly['precipitation_probability'] as List?;

      if (times != null && temps != null) {
        hourlyList = [];
        // Get next 12 hours
        final limit = times.length > 12 ? 12 : times.length;
        for (int i = 0; i < limit; i++) {
          hourlyList.add(HourlyForecast(
            time: DateTime.parse(times[i]),
            temperature: temps[i]?.toDouble() ?? 0.0,
            weatherCode: codes?[i]?.toInt() ?? 0,
            precipitationProbability: precip?[i]?.toDouble(),
          ));
        }
      }
    }

    return WeatherData(
      temperature: current['temperature_2m']?.toDouble() ?? 0.0,
      weatherCode: current['weather_code']?.toInt() ?? 0,
      maxTemp: daily['temperature_2m_max']?[0]?.toDouble() ?? 0.0,
      minTemp: daily['temperature_2m_min']?[0]?.toDouble() ?? 0.0,
      precipitationProbability: current['precipitation_probability']?.toDouble(),
      windSpeed: current['wind_speed_10m']?.toDouble(),
      humidity: current['relative_humidity_2m']?.toDouble(),
      hourlyForecast: hourlyList,
    );
  }

  String get weatherDescription {
    // ... existing switch statement unchanged
  }

  /// Generate a text summary for AI processing
  String toAiContextString() {
    final buffer = StringBuffer();
    buffer.writeln('Current weather conditions:');
    buffer.writeln('- Temperature: ${temperature.round()}°C');
    buffer.writeln('- Condition: $weatherDescription');
    buffer.writeln('- High/Low: ${maxTemp.round()}°C / ${minTemp.round()}°C');
    if (precipitationProbability != null) {
      buffer.writeln('- Precipitation chance: ${precipitationProbability!.round()}%');
    }
    if (windSpeed != null) {
      buffer.writeln('- Wind speed: ${windSpeed!.round()} km/h');
    }
    if (humidity != null) {
      buffer.writeln('- Humidity: ${humidity!.round()}%');
    }
    if (hourlyForecast != null && hourlyForecast!.isNotEmpty) {
      buffer.writeln('Next few hours:');
      for (final hour in hourlyForecast!.take(6)) {
        buffer.writeln('- ${hour.time.hour}:00: ${hour.temperature.round()}°C, ${hour.weatherCodeDescription}');
      }
    }
    return buffer.toString();
  }
}

class HourlyForecast {
  final DateTime time;
  final double temperature;
  final int weatherCode;
  final double? precipitationProbability;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    this.precipitationProbability,
  });

  String get weatherCodeDescription {
    switch (weatherCode) {
      case 0: return 'Clear';
      case 1: case 2: case 3: return 'Cloudy';
      case 45: case 48: return 'Fog';
      case 51: case 53: case 55: return 'Drizzle';
      case 61: case 63: case 65: return 'Rain';
      case 71: case 73: case 75: return 'Snow';
      case 95: case 96: case 99: return 'Thunderstorm';
      default: return 'Unknown';
    }
  }
}
```

**Step 3: Run build to verify no errors**

Run: `cd /Users/manash/projects/glance && flutter analyze lib/models/weather_data.dart`
Expected: No issues

**Step 4: Commit**

```bash
git add lib/models/weather_data.dart
git commit -m "feat(weather): extend WeatherData with hourly forecasts and AI context

Add precipitation probability, wind speed, humidity, and hourly forecast
data to support AI-based weather action generation.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Update Weather Service for Extended Data

**Files:**
- Modify: `lib/services/weather_service.dart`

**Step 1: Update API URL to include additional parameters**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  static const double _lat = 52.52;
  static const double _lng = 13.41;
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  static Future<WeatherData> getWeather() async {
    try {
      final url = '$_baseUrl'
          '?latitude=$_lat'
          '&longitude=$_lng'
          '&current=temperature_2m,weather_code,precipitation_probability,wind_speed_10m,relative_humidity_2m'
          '&hourly=temperature_2m,weather_code,precipitation_probability'
          '&daily=temperature_2m_max,temperature_2m_min'
          '&timezone=auto'
          '&forecast_hours=12';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }
}
```

**Step 2: Run build to verify**

Run: `cd /Users/manash/projects/glance && flutter analyze lib/services/weather_service.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/services/weather_service.dart
git commit -m "feat(weather): extend API call for hourly forecasts

Add precipitation probability, wind speed, humidity, and hourly
forecast parameters to Open-Meteo API request.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Create Weather Action Model

**Files:**
- Create: `lib/models/weather_action.dart`

**Step 1: Create weather action data model**

```dart
/// Represents an AI-generated weather action/recommendation
class WeatherAction {
  final String action;
  final String? icon;
  final DateTime generatedAt;
  final WeatherActionSource source;

  WeatherAction({
    required this.action,
    this.icon,
    required this.generatedAt,
    required this.source,
  });

  factory WeatherAction.fallback(String action, {String? icon}) {
    return WeatherAction(
      action: action,
      icon: icon,
      generatedAt: DateTime.now(),
      source: WeatherActionSource.ruleBased,
    );
  }

  factory WeatherAction.fromAi(String action, {String? icon}) {
    return WeatherAction(
      action: action,
      icon: icon,
      generatedAt: DateTime.now(),
      source: WeatherActionSource.aiGenerated,
    );
  }

  bool get isStale {
    // Consider action stale after 30 minutes
    return DateTime.now().difference(generatedAt).inMinutes > 30;
  }
}

enum WeatherActionSource {
  aiGenerated,
  ruleBased,
}
```

**Step 2: Run build to verify**

Run: `cd /Users/manash/projects/glance && flutter analyze lib/models/weather_action.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/models/weather_action.dart
git commit -m "feat(weather): add WeatherAction model

Model for AI-generated weather recommendations with source tracking
and staleness detection.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Create Rule-Based Weather Action Generator (Fallback)

**Files:**
- Create: `lib/services/weather_action_fallback.dart`

**Step 1: Create fallback rule-based action generator**

This provides weather actions when AI is unavailable.

```dart
import '../models/weather_data.dart';
import '../models/weather_action.dart';

/// Generates weather actions using rule-based logic (fallback when AI unavailable)
class WeatherActionFallback {
  static WeatherAction generate(WeatherData weather) {
    final actions = <String>[];

    // Temperature-based recommendations
    if (weather.temperature < 0) {
      actions.add('Bundle up! It\'s freezing outside');
    } else if (weather.temperature < 10) {
      actions.add('Wear a warm jacket today');
    } else if (weather.temperature > 30) {
      actions.add('Stay hydrated in the heat');
    }

    // Weather code-based recommendations
    switch (weather.weatherCode) {
      case 51: case 53: case 55: // Drizzle
        actions.add('Light rain expected - bring an umbrella');
        break;
      case 61: case 63: case 65: // Rain
        actions.add('Take an umbrella - rain expected');
        break;
      case 71: case 73: case 75: // Snow
        actions.add('Snow today - dress warmly and wear appropriate footwear');
        break;
      case 95: case 96: case 99: // Thunderstorm
        actions.add('Thunderstorms expected - stay indoors if possible');
        break;
      case 45: case 48: // Fog
        actions.add('Foggy conditions - drive carefully');
        break;
    }

    // Precipitation probability
    if (weather.precipitationProbability != null &&
        weather.precipitationProbability! > 50) {
      if (!actions.any((a) => a.contains('umbrella'))) {
        actions.add('High chance of precipitation - umbrella recommended');
      }
    }

    // Wind speed
    if (weather.windSpeed != null && weather.windSpeed! > 40) {
      actions.add('Strong winds today - secure loose items');
    }

    // Check hourly forecast for changes
    if (weather.hourlyForecast != null && weather.hourlyForecast!.isNotEmpty) {
      final hasRainLater = weather.hourlyForecast!.any((h) =>
        [51, 53, 55, 61, 63, 65].contains(h.weatherCode));
      if (hasRainLater && !actions.any((a) => a.contains('umbrella'))) {
        actions.add('Rain expected later - take an umbrella');
      }
    }

    // Default if no specific actions
    if (actions.isEmpty) {
      if (weather.weatherCode == 0) {
        actions.add('Perfect weather - enjoy your day!');
      } else {
        actions.add('Have a great day!');
      }
    }

    // Return the most relevant action (first one)
    return WeatherAction.fallback(
      actions.first,
      icon: _getIconForAction(actions.first),
    );
  }

  static String? _getIconForAction(String action) {
    if (action.contains('umbrella')) return 'umbrella';
    if (action.contains('warm') || action.contains('jacket') || action.contains('freezing')) return 'cold';
    if (action.contains('heat') || action.contains('hydrated')) return 'hot';
    if (action.contains('snow')) return 'snow';
    if (action.contains('thunder')) return 'storm';
    if (action.contains('wind')) return 'wind';
    if (action.contains('fog')) return 'fog';
    return 'sun';
  }
}
```

**Step 2: Run build to verify**

Run: `cd /Users/manash/projects/glance && flutter analyze lib/services/weather_action_fallback.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/services/weather_action_fallback.dart
git commit -m "feat(weather): add rule-based weather action fallback

Provides weather recommendations when AI is unavailable using
rule-based logic based on temperature, weather codes, and forecasts.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Create Native Android ML Kit Integration (Kotlin)

**Files:**
- Create: `android/app/src/main/kotlin/com/example/glance/WeatherAiChannel.kt`
- Modify: `android/app/src/main/kotlin/com/example/glance/MainActivity.kt`
- Modify: `android/app/build.gradle.kts`

**Step 1: Add ML Kit GenAI dependency to build.gradle.kts**

Edit `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.glance"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.glance"
        minSdk = 26  // Required for ML Kit GenAI
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // ML Kit GenAI Summarization (includes Gemini Nano)
    implementation("com.google.mlkit:genai-summarization:1.0.0-beta1")
}

flutter {
    source = "../.."
}
```

**Step 2: Create WeatherAiChannel.kt**

Create `android/app/src/main/kotlin/com/example/glance/WeatherAiChannel.kt`:

```kotlin
package com.example.glance

import android.content.Context
import com.google.mlkit.genai.summarization.Summarization
import com.google.mlkit.genai.summarization.SummarizerOptions
import com.google.mlkit.genai.summarization.SummarizationRequest
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.common.DownloadCallback
import com.google.mlkit.genai.common.GenAiException
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.*
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class WeatherAiChannel(
    private val context: Context,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "com.example.glance/weather_ai")
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var summarizer: com.google.mlkit.genai.summarization.Summarizer? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkAvailability" -> checkAvailability(result)
            "generateAction" -> {
                val weatherContext = call.argument<String>("weatherContext")
                if (weatherContext != null) {
                    generateAction(weatherContext, result)
                } else {
                    result.error("INVALID_ARGUMENT", "weatherContext is required", null)
                }
            }
            "dispose" -> {
                dispose()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun checkAvailability(result: MethodChannel.Result) {
        scope.launch {
            try {
                val options = SummarizerOptions.builder(context)
                    .setInputType(SummarizerOptions.InputType.ARTICLE)
                    .setOutputType(SummarizerOptions.OutputType.ONE_BULLET)
                    .setLanguage(SummarizerOptions.Language.ENGLISH)
                    .build()

                val tempSummarizer = Summarization.getClient(options)
                val status = suspendCancellableCoroutine { cont ->
                    tempSummarizer.checkFeatureStatus()
                        .addOnSuccessListener { status -> cont.resume(status) }
                        .addOnFailureListener { e -> cont.resumeWithException(e) }
                }
                tempSummarizer.close()

                result.success(mapOf(
                    "available" to (status == FeatureStatus.AVAILABLE ||
                                   status == FeatureStatus.DOWNLOADABLE ||
                                   status == FeatureStatus.DOWNLOADING),
                    "status" to when (status) {
                        FeatureStatus.AVAILABLE -> "available"
                        FeatureStatus.DOWNLOADABLE -> "downloadable"
                        FeatureStatus.DOWNLOADING -> "downloading"
                        else -> "unavailable"
                    }
                ))
            } catch (e: Exception) {
                result.success(mapOf(
                    "available" to false,
                    "status" to "error",
                    "error" to e.message
                ))
            }
        }
    }

    private fun generateAction(weatherContext: String, result: MethodChannel.Result) {
        scope.launch {
            try {
                // Create prompt for weather action
                val prompt = """
                    Based on the following weather conditions, provide ONE short,
                    actionable recommendation (max 10 words) for someone going outside.
                    Focus on practical advice like bringing an umbrella, wearing warm clothes, etc.

                    $weatherContext

                    Recommendation:
                """.trimIndent()

                val options = SummarizerOptions.builder(context)
                    .setInputType(SummarizerOptions.InputType.ARTICLE)
                    .setOutputType(SummarizerOptions.OutputType.ONE_BULLET)
                    .setLanguage(SummarizerOptions.Language.ENGLISH)
                    .build()

                summarizer = Summarization.getClient(options)

                // Check and download if needed
                val status = suspendCancellableCoroutine { cont ->
                    summarizer!!.checkFeatureStatus()
                        .addOnSuccessListener { status -> cont.resume(status) }
                        .addOnFailureListener { e -> cont.resumeWithException(e) }
                }

                if (status == FeatureStatus.DOWNLOADABLE) {
                    // Wait for download
                    suspendCancellableCoroutine { cont ->
                        summarizer!!.downloadFeature(object : DownloadCallback {
                            override fun onDownloadStarted(bytesToDownload: Long) {}
                            override fun onDownloadProgress(totalBytesDownloaded: Long) {}
                            override fun onDownloadFailed(e: GenAiException) {
                                cont.resumeWithException(e)
                            }
                            override fun onDownloadCompleted() {
                                cont.resume(Unit)
                            }
                        })
                    }
                } else if (status == FeatureStatus.UNAVAILABLE) {
                    result.success(mapOf(
                        "success" to false,
                        "error" to "AI features unavailable on this device"
                    ))
                    return@launch
                }

                // Run inference
                val request = SummarizationRequest.builder(prompt).build()
                val summary = suspendCancellableCoroutine { cont ->
                    summarizer!!.runInference(request)
                        .addOnSuccessListener { summaryResult ->
                            cont.resume(summaryResult.summary)
                        }
                        .addOnFailureListener { e ->
                            cont.resumeWithException(e)
                        }
                }

                result.success(mapOf(
                    "success" to true,
                    "action" to summary.trim()
                ))

            } catch (e: Exception) {
                result.success(mapOf(
                    "success" to false,
                    "error" to (e.message ?: "Unknown error")
                ))
            }
        }
    }

    fun dispose() {
        summarizer?.close()
        summarizer = null
        scope.cancel()
    }
}
```

**Step 3: Update MainActivity.kt**

Edit `android/app/src/main/kotlin/com/example/glance/MainActivity.kt`:

```kotlin
package com.example.glance

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    private var weatherAiChannel: WeatherAiChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        weatherAiChannel = WeatherAiChannel(
            this,
            flutterEngine.dartExecutor.binaryMessenger
        )
    }

    override fun onDestroy() {
        weatherAiChannel?.dispose()
        super.onDestroy()
    }
}
```

**Step 4: Build Android project to verify**

Run: `cd /Users/manash/projects/glance && flutter build apk --debug 2>&1 | head -50`
Expected: Build succeeds (may take a while for first dependency download)

**Step 5: Commit**

```bash
git add android/app/build.gradle.kts
git add android/app/src/main/kotlin/com/example/glance/WeatherAiChannel.kt
git add android/app/src/main/kotlin/com/example/glance/MainActivity.kt
git commit -m "feat(android): add ML Kit GenAI integration for weather actions

Add platform channel to communicate with Gemini Nano via ML Kit GenAI
Summarization API. Includes availability checking and fallback handling.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Create Flutter Weather AI Service (Platform Channel Client)

**Files:**
- Create: `lib/services/weather_ai_service.dart`

**Step 1: Create platform channel client**

```dart
import 'package:flutter/services.dart';
import '../models/weather_data.dart';
import '../models/weather_action.dart';
import 'weather_action_fallback.dart';

/// Service for generating AI-based weather actions via platform channel
class WeatherAiService {
  static const _channel = MethodChannel('com.example.glance/weather_ai');
  static bool? _isAvailable;

  /// Check if on-device AI is available
  static Future<bool> checkAvailability() async {
    if (_isAvailable != null) return _isAvailable!;

    try {
      final result = await _channel.invokeMethod<Map>('checkAvailability');
      _isAvailable = result?['available'] == true;
      return _isAvailable!;
    } on PlatformException {
      _isAvailable = false;
      return false;
    } on MissingPluginException {
      // Platform channel not available (e.g., on web/desktop)
      _isAvailable = false;
      return false;
    }
  }

  /// Generate a weather action using AI or fallback to rules
  static Future<WeatherAction> generateAction(WeatherData weather) async {
    // First check if AI is available
    final aiAvailable = await checkAvailability();

    if (!aiAvailable) {
      return WeatherActionFallback.generate(weather);
    }

    try {
      final result = await _channel.invokeMethod<Map>('generateAction', {
        'weatherContext': weather.toAiContextString(),
      });

      if (result?['success'] == true && result?['action'] != null) {
        return WeatherAction.fromAi(result!['action'] as String);
      } else {
        // AI failed, use fallback
        return WeatherActionFallback.generate(weather);
      }
    } on PlatformException {
      return WeatherActionFallback.generate(weather);
    }
  }

  /// Dispose of native resources
  static Future<void> dispose() async {
    try {
      await _channel.invokeMethod('dispose');
    } catch (_) {
      // Ignore disposal errors
    }
  }
}
```

**Step 2: Run build to verify**

Run: `cd /Users/manash/projects/glance && flutter analyze lib/services/weather_ai_service.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/services/weather_ai_service.dart
git commit -m "feat(weather): add WeatherAiService for platform channel communication

Flutter service that communicates with native Android ML Kit GenAI
via platform channel, with automatic fallback to rule-based actions.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 7: Create Weather Action Widget

**Files:**
- Create: `lib/widgets/weather_action_widget.dart`

**Step 1: Create the weather action widget**

```dart
import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../models/weather_action.dart';
import '../services/weather_ai_service.dart';
import '../main.dart'; // For extension methods

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
        borderRadius: BorderRadius.circular(16),
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
```

**Step 2: Run build to verify**

Run: `cd /Users/manash/projects/glance && flutter analyze lib/widgets/weather_action_widget.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/widgets/weather_action_widget.dart
git commit -m "feat(ui): add WeatherActionWidget for displaying AI suggestions

Widget displays AI-generated or rule-based weather recommendations
with loading state, error handling, and source indication.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 8: Add Settings for Weather Actions Toggle

**Files:**
- Modify: `lib/services/settings_service.dart`
- Modify: `lib/widgets/settings_dialog.dart`

**Step 1: Add settings key for weather actions**

Add to `lib/services/settings_service.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transport_type.dart';

class SettingsService {
  static const String _keyWeatherScale = 'weather_scale';
  static const String _keyDepartureScale = 'departure_scale';
  static const String _keyDefaultStationId = 'default_station_id';
  static const String _keyDefaultTransportType = 'default_transport_type';
  static const String _keySkipMinutes = 'skip_minutes';
  static const String _keyDurationMinutes = 'duration_minutes';
  static const String _keyShowWeatherActions = 'show_weather_actions';

  // ... existing methods unchanged ...

  static Future<void> saveShowWeatherActions(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowWeatherActions, show);
  }

  static Future<bool> getShowWeatherActions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowWeatherActions) ?? false;
  }
}
```

**Step 2: Update SettingsDialog**

The SettingsDialog needs to be updated to include the weather actions toggle. Add a new parameter and switch widget.

Add to constructor parameters in `lib/widgets/settings_dialog.dart`:
```dart
final bool initialShowWeatherActions;
final Function(double, double, String, TransportType, int, int, bool) onSave;
```

Add state variable:
```dart
late bool _showWeatherActions;
```

Initialize in initState:
```dart
_showWeatherActions = widget.initialShowWeatherActions;
```

Add switch widget in the settings list:
```dart
SwitchListTile(
  title: const Text('Show Weather Tips'),
  subtitle: const Text('Replace logo with AI weather recommendations'),
  value: _showWeatherActions,
  onChanged: (value) {
    setState(() {
      _showWeatherActions = value;
    });
  },
),
```

Update save callback to include the new parameter.

**Step 3: Run build to verify**

Run: `cd /Users/manash/projects/glance && flutter analyze lib/services/settings_service.dart lib/widgets/settings_dialog.dart`
Expected: No issues (will show some until dashboard is updated)

**Step 4: Commit**

```bash
git add lib/services/settings_service.dart lib/widgets/settings_dialog.dart
git commit -m "feat(settings): add toggle for weather actions display

Add setting to switch between logo and AI weather recommendations
in the dashboard widget slot.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 9: Integrate Weather Actions into Dashboard

**Files:**
- Modify: `lib/screens/dashboard_screen.dart`

**Step 1: Add imports and state variables**

Add at top of file:
```dart
import '../widgets/weather_action_widget.dart';
import '../services/settings_service.dart';
```

Add state variables:
```dart
bool _showWeatherActions = false;
final GlobalKey<WeatherActionWidgetState> _weatherActionKey = GlobalKey();
```

**Step 2: Load setting in initState**

In `_loadSettings()` method, add:
```dart
final showWeatherActions = await SettingsService.getShowWeatherActions();
setState(() {
  _showWeatherActions = showWeatherActions;
});
```

**Step 3: Update _buildLogoWidget to conditionally show weather actions**

Replace `_buildLogoWidget()`:
```dart
Widget _buildLogoWidget() {
  if (_showWeatherActions) {
    return WeatherActionWidget(
      key: _weatherActionKey,
      scaleFactor: 1.0,
    );
  }

  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(16),
      border: isDark ? null : Border.all(color: context.borderColor),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: Image.asset('assets/images/logo.png', height: 80)),
        const SizedBox(height: 8),
        Text(
          'Glance',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          _version,
          style: TextStyle(fontSize: 12, color: context.textTertiary),
        ),
      ],
    ),
  );
}
```

**Step 4: Trigger weather action generation on weather refresh**

In `_refreshAll()` or wherever weather is refreshed, add:
```dart
if (_showWeatherActions && _weatherActionKey.currentState != null) {
  // Get weather data and generate action
  final weatherState = _weatherKey.currentState;
  if (weatherState != null && weatherState.weatherData != null) {
    _weatherActionKey.currentState!.generateAction(weatherState.weatherData!);
  }
}
```

**Step 5: Update settings dialog call**

Update the SettingsDialog instantiation to include the new parameter.

**Step 6: Run build to verify**

Run: `cd /Users/manash/projects/glance && flutter analyze lib/screens/dashboard_screen.dart`
Expected: No issues

**Step 7: Commit**

```bash
git add lib/screens/dashboard_screen.dart
git commit -m "feat(dashboard): integrate weather actions into logo slot

Conditionally display WeatherActionWidget or logo based on user
settings. Weather actions regenerate on each weather refresh.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 10: Test on Android Tablet

**Files:** None (testing task)

**Step 1: Build debug APK**

Run: `cd /Users/manash/projects/glance && flutter build apk --debug`
Expected: BUILD SUCCESSFUL

**Step 2: Install on Android tablet**

Run: `adb install build/app/outputs/flutter-apk/app-debug.apk`
Or use: `flutter install`

**Step 3: Manual testing checklist**

1. [ ] Launch app on tablet
2. [ ] Go to Settings
3. [ ] Enable "Show Weather Tips" toggle
4. [ ] Verify weather action widget appears instead of logo
5. [ ] Check if AI generation works (shows "AI Suggestion" label)
6. [ ] If AI unavailable, verify fallback works (shows "Weather Tip" label)
7. [ ] Pull-to-refresh or wait for auto-refresh
8. [ ] Verify action updates with weather changes
9. [ ] Disable toggle, verify logo returns
10. [ ] Test in both portrait and landscape orientations

**Step 4: Document any issues found**

Create notes for any bugs or improvements needed.

---

## Task 11: Final Cleanup and Documentation

**Files:**
- Optional: Update `README.md` if documenting new features

**Step 1: Run full analysis**

Run: `cd /Users/manash/projects/glance && flutter analyze`
Expected: No issues found

**Step 2: Run tests**

Run: `cd /Users/manash/projects/glance && flutter test`
Expected: All tests pass

**Step 3: Final commit (if any cleanup needed)**

```bash
git add -A
git commit -m "chore: cleanup and finalize weather actions feature

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Summary

This plan implements AI-based weather actions for Android tablets with:

1. **Extended weather data** - hourly forecasts, precipitation, wind, humidity
2. **Native Android integration** - ML Kit GenAI with Gemini Nano via platform channels
3. **Graceful fallback** - rule-based actions when AI is unavailable
4. **User control** - settings toggle to switch between logo and weather actions
5. **Consistent UX** - matches existing glassmorphic design language

**Key considerations:**
- Gemini Nano is only available on supported devices (Pixel 6+, newer Samsung, etc.)
- Fallback ensures all Android tablets get weather recommendations
- Platform channel pattern allows future expansion (iOS, etc.)
- Minimal changes to existing architecture
