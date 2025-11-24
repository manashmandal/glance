# Glance Dashboard - Design Specifications

## Overview
A high-fidelity Flutter tablet application dashboard with modern, minimalist design principles optimized for landscape orientation and 4K displays.

## Layout Structure

### Grid System
- **Layout Type**: Bento box grid system
- **Orientation**: Landscape (forced)
- **Padding**: 24px all sides
- **Gap between modules**: 24px

### Module Distribution
```
┌─────────────────────────────────────────┐
│  [Clock Module - 3:2]  [Weather - 2:2] │
│                                          │
├─────────────────────────────────────────┤
│  [Train Departures - Full Width 5:3]   │
│                                          │
│                                          │
└─────────────────────────────────────────┘
```

## Color Palette

### Base Colors
- **Background**: `#1A1D23` (Deep charcoal)
- **Surface**: `#252931` (Card background)
- **Primary Text**: `#FFFFFF` (White)
- **Secondary Text**: `#FFFFFF` with 70% opacity
- **Tertiary Text**: `#FFFFFF` with 60% opacity

### Accent Colors
- **Red Line (RE1)**: `#EF4444`
- **Blue Line (FEX)**: `#3B82F6`
- **Green Line (RB10)**: `#10B981`
- **Status Green**: `#10B981`
- **Status Yellow**: `#FBBF24`
- **Weather Gradient**: Blue (`#3B82F6`) to Orange (`#F59E0B`)

## Typography

### Font Family
- **Primary**: Inter (fallback to system sans-serif)
- **Alternative**: Roboto

### Font Sizes & Weights
- **Clock Time**: 96px, Bold (Weight: 700), -4px letter spacing
- **Clock Date**: 24px, Regular (Weight: 400), 0.5px letter spacing
- **Weather Location/Temp**: 32px, Bold (Weight: 700)
- **Weather Description**: 18px, Medium (Weight: 500)
- **Weather High/Low**: 16px, Regular (Weight: 400)
- **Train Header**: 28px, Bold (Weight: 700)
- **Train Table Headers**: 16px, Semi-bold (Weight: 600)
- **Train Time**: 20px, Semi-bold (Weight: 600), Tabular figures
- **Train Destination**: 18px, Medium (Weight: 500)
- **Train Line**: 16px, Bold (Weight: 700)
- **Train Platform**: 18px, Medium (Weight: 500)
- **Train Status**: 16px, Semi-bold (Weight: 600)

## Visual Effects

### Glassmorphism
- **Backdrop Blur**: 10px (sigmaX, sigmaY)
- **Surface Opacity**: 60% (#252931 at 0.6)
- **Border**: 1px solid white at 10% opacity

### Shadows
- **Primary Shadow**: Black at 30% opacity, 20px blur, 10px Y-offset
- **Weather Glow**: Blue at 20% opacity, 30px blur, 10px Y-offset

### Border Radius
- **All Modules**: 24px
- **Table Header**: 12px
- **Train Rows**: 12px
- **Line Badges**: 8px

## Module Specifications

### Clock Module (Top Left)
- **Flex**: 3 (60% of top row width)
- **Padding**: 40px
- **Content**: 
  - Live time display (HH:mm format)
  - Current date (EEEE, MMMM d format)
- **Alignment**: Left-aligned, vertically centered

### Weather Module (Top Right)
- **Flex**: 2 (40% of top row width)
- **Padding**: 32px
- **Content**:
  - Weather icon (100x100px gradient circle)
  - Location and temperature
  - Weather description
  - High/Low temperatures
- **Gradient**: Blue-to-orange diagonal gradient at 30% opacity
- **Alignment**: Center-aligned

### Weather Icon
- **Size**: 100x100px circle
- **Background**: Gradient from blue to orange
- **Icons**: 
  - Sun icon (40px, positioned top-right)
  - Cloud icon (50px, positioned bottom-left)

### Train Departures Module (Bottom)
- **Width**: 100% (full width)
- **Flex**: 3 (60% of vertical space)
- **Padding**: 32px
- **Header**: "Regional Train Departures"
- **Table Structure**:
  - Header row with 5 columns
  - Data rows with hover states

### Train Table Columns
1. **Time**: 80px fixed width, tabular figures
2. **Destination**: Flex 3 (expands)
3. **Line**: 120px fixed width with colored badge
4. **Platform**: 100px fixed width
5. **Status**: 120px fixed width with color coding

### Line Badges
- **Padding**: 12px horizontal, 6px vertical
- **Background**: Line color at 20% opacity
- **Border**: 1.5px solid line color at 50% opacity
- **Indicator**: 8px circle filled with line color
- **Border Radius**: 8px

## Sample Data

### Train Departures
1. **08:52** → Potsdam Hbf | RE1 (Red) | Pl. 3 | On Time (Green)
2. **09:05** → Airport BER | FEX (Blue) | Pl. 4 | +5 min Delay (Yellow)
3. **09:12** → Nauen | RB10 (Green) | Pl. 1 | On Time (Green)
4. **09:30** → Frankfurt (Oder) | RE1 (Red) | Pl. 2 | On Time (Green)

### Weather Data
- **Location**: Berlin
- **Temperature**: 14°C
- **Condition**: Partly Cloudy
- **High**: 16°
- **Low**: 9°

### Clock Data
- **Time**: 08:45 (live updating)
- **Date**: Monday, November 24 (current date)

## Responsive Behavior

### Target Devices
- Tablets (7" - 13")
- Large tablets / Folding devices
- Desktop preview

### Orientation Lock
- Landscape only (DeviceOrientation.landscapeLeft, landscapeRight)

## Accessibility

- High contrast text on dark backgrounds
- Readable from 2-3 meters distance
- Color-coded status with text labels
- Large touch targets for interactive elements (future)

## Material Design 3 Principles
- Material You color system
- Dynamic color schemes
- Elevation through shadows (not solid surfaces)
- Motion and animations (clock updates every second)
- Large, bold typography
- Spacious layouts with breathing room

## Performance Optimizations
- Efficient widget rebuilds (only clock updates every second)
- Static content for weather and trains (can be connected to APIs)
- Minimal overdraw with proper clipping
- Optimized blur effects with ClipRRect

## Future Enhancements
- Real-time data integration (weather API, train API)
- Smooth animations and transitions
- Multiple pages/screens
- Settings panel
- Customizable widgets
- Location-based weather
- Notification system

