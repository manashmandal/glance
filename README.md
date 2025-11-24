# Glance Dashboard

A modern, minimalist Flutter tablet dashboard application featuring a beautiful dark mode UI with glassmorphism effects.

## Features

- 🕐 **Live Digital Clock** - Real-time clock display with date
- 🌤️ **Weather Widget** - Beautiful weather card with gradient effects
- 🚆 **Train Departures Board** - Regional train information with status indicators
- 📱 **Tablet Optimized** - Designed for landscape orientation on tablets
- 🎨 **Modern UI** - Material Design 3 with glassmorphism and bento box layout
- 🌙 **Dark Mode** - Beautiful dark theme optimized for readability

## Design Features

- Deep charcoal background (#1A1D23)
- Frosted glassmorphism effects with backdrop blur
- Bento box grid layout with rounded corners
- High contrast typography for distance readability
- Soft drop shadows for depth
- Gradient glows on weather widget
- Color-coded train line badges

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- An IDE (VS Code, Android Studio, or IntelliJ)

### Installation

1. Clone the repository or navigate to the project directory:
```bash
cd /Users/manash/Projects/glance
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run -d macos
```

### For Tablet Testing

To test on different tablet sizes:
```bash
flutter run -d <device_id>
```

Or use the Flutter device simulator with tablet dimensions.

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── screens/
│   └── dashboard_screen.dart          # Main dashboard layout
└── widgets/
    ├── clock_widget.dart              # Digital clock module
    ├── weather_widget.dart            # Weather display module
    └── train_departures_widget.dart   # Train schedule table
```

## Customization

### Changing Colors

Edit the theme in `lib/main.dart`:
```dart
colorScheme: ColorScheme.dark(
  background: const Color(0xFF1A1D23),
  surface: const Color(0xFF252931),
  ...
)
```

### Updating Train Data

Modify the train rows in `lib/widgets/train_departures_widget.dart` to connect to a real API or update static data.

### Weather Data

Currently displays static weather data. Integrate with a weather API by modifying `lib/widgets/weather_widget.dart`.

## Technologies Used

- Flutter 3.x
- Material Design 3
- Dart
- intl package for date/time formatting

## License

This project is created as a UI demonstration.

## Screenshots

The application features:
- Top left: Large digital clock module (08:45, Monday, November 24)
- Top right: Weather widget (Berlin, 14°C, Partly Cloudy with gradient glow)
- Bottom: Full-width train departures table with 4 trains showing times, destinations, line badges, platforms, and status

All widgets use glassmorphism effects with backdrop blur for a modern, premium appearance.

