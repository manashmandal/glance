import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'family_palette.dart';

/// Typography tokens for the Family Dashboard.
///
/// Three families:
/// - Inter Tight — display headlines and UI text
/// - Geist Mono — numbers, codes, labels that want tabular feel
/// - Inter — default body and long-form labels
/// - Instrument Serif — italic editorial tone (weather tip)
class FamilyType {
  const FamilyType._();

  // --- Display ---

  /// The huge destination banner (e.g. "Flughafen BER").
  static TextStyle destination() => GoogleFonts.interTight(
        color: FamilyPalette.textPrimary,
        fontSize: 88,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.035 * 88,
        height: 1.0,
      );

  /// The massive countdown number (e.g. "8").
  static TextStyle countdownNumber() => GoogleFonts.geistMono(
        color: FamilyPalette.crimson,
        fontSize: 200,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.07 * 200,
        height: 0.82,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// The "in"/"min" labels flanking the countdown number.
  static TextStyle countdownLabel() => GoogleFonts.interTight(
        color: FamilyPalette.textTertiary,
        fontSize: 42,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.01 * 42,
        height: 52 / 42,
      );

  /// Clock time (e.g. "2:32 PM").
  static TextStyle clock() => GoogleFonts.geistMono(
        color: FamilyPalette.textPrimary,
        fontSize: 60,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.04 * 60,
        height: 0.9,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // --- Headings ---

  /// Current station name in the top strip.
  static TextStyle stationLarge() => GoogleFonts.inter(
        color: FamilyPalette.textSecondary,
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 40 / 32,
      );

  /// Brand wordmark ("glance").
  static TextStyle brandWordmark() => GoogleFonts.interTight(
        color: FamilyPalette.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.05 * 28,
        height: 1.0,
      );

  /// Date under the clock (e.g. "Thursday, April 19").
  static TextStyle date() => GoogleFonts.inter(
        color: FamilyPalette.textSecondary,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.06 * 18,
        height: 22 / 18,
      );

  // --- Lists ---

  /// Time column in the upcoming list.
  static TextStyle upcomingTime() => GoogleFonts.geistMono(
        color: FamilyPalette.textPrimary,
        fontSize: 26,
        fontWeight: FontWeight.w500,
        height: 32 / 26,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Destination column in the upcoming list.
  static TextStyle upcomingName() => GoogleFonts.interTight(
        color: FamilyPalette.textPrimary,
        fontSize: 26,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.02 * 26,
        height: 32 / 26,
      );

  /// Line code (e.g. "RE8") in the upcoming list.
  static TextStyle upcomingLineCode() => GoogleFonts.geistMono(
        color: FamilyPalette.textPrimary,
        fontSize: 14,
        height: 18 / 14,
      );

  /// "On time" status — neutral off-white; colour is reserved for delays.
  static TextStyle statusOnTime() => GoogleFonts.inter(
        color: FamilyPalette.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 18 / 14,
      );

  /// Delay marker (e.g. "+6'").
  static TextStyle statusDelay() => GoogleFonts.geistMono(
        color: FamilyPalette.amber,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 20 / 16,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // --- Platform card ---

  /// Platform number (big).
  static TextStyle platformNumber() => GoogleFonts.geistMono(
        color: FamilyPalette.textPrimary,
        fontSize: 42,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.02 * 42,
        height: 40 / 42,
      );

  /// Line code inside platform card (e.g. "RE8").
  static TextStyle lineCodeLarge() => GoogleFonts.geistMono(
        color: FamilyPalette.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.04 * 18,
        height: 22 / 18,
      );

  // --- Weather ---

  /// Big temperature number.
  static TextStyle tempLarge() => GoogleFonts.geistMono(
        color: FamilyPalette.textPrimary,
        fontSize: 80,
        letterSpacing: -0.05 * 80,
        height: 0.85,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Degree symbol next to the big temp.
  static TextStyle tempDegree() => GoogleFonts.interTight(
        color: FamilyPalette.textPrimary,
        fontSize: 30,
        height: 1.0,
      );

  /// Condition line (e.g. "Partly cloudy · light rain at 6 PM").
  static TextStyle weatherCondition() => GoogleFonts.inter(
        color: FamilyPalette.textSecondary,
        fontSize: 20,
        height: 1.4,
      );

  /// Italic advisory tip.
  static TextStyle weatherTip() => GoogleFonts.instrumentSerif(
        color: FamilyPalette.textSecondary,
        fontSize: 20,
        fontStyle: FontStyle.italic,
        height: 1.4,
      );

  /// Forecast column temp.
  static TextStyle forecastTemp() => GoogleFonts.geistMono(
        color: FamilyPalette.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.02 * 16,
        height: 18 / 16,
      );

  // --- Section labels ---

  /// Section heading (e.g. "UPCOMING").
  static TextStyle sectionLabel() => GoogleFonts.inter(
        color: FamilyPalette.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.18 * 14,
        height: 18 / 14,
      );

  /// Caps-small metadata (e.g. "LEAVE BY", "PLATFORM", "NEXT 8 HOURS").
  static TextStyle metaCaps({Color? color}) => GoogleFonts.inter(
        color: color ?? FamilyPalette.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.16 * 11,
        height: 14 / 11,
      );

  /// Wider-tracked caps for forecast hours ("NOW", "4 PM").
  static TextStyle forecastHour() => GoogleFonts.inter(
        color: FamilyPalette.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.08 * 11,
        height: 14 / 11,
      );

  /// The person label in the up-next callout ("ANNA").
  static TextStyle eyebrow({required Color color}) => GoogleFonts.inter(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.22 * 10,
        height: 12 / 10,
      );

  /// Up-next time range ("3:00 – 4:30").
  static TextStyle eventTimeRange() => GoogleFonts.geistMono(
        color: FamilyPalette.textEventRange,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.02 * 11,
        height: 14 / 11,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Up-next event title.
  static TextStyle eventTitle() => GoogleFonts.interTight(
        color: FamilyPalette.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.02 * 20,
        height: 22 / 20,
      );

  /// "REGIONAL" subdued caption beside line code.
  static TextStyle lineCategory() => GoogleFonts.inter(
        color: FamilyPalette.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.16 * 11,
        height: 14 / 11,
      );

  // --- Brand / meta ---

  static TextStyle metaMono({Color? color}) => GoogleFonts.geistMono(
        color: color ?? FamilyPalette.textTertiary,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.04 * 10,
        height: 14 / 10,
      );

  /// Route preview strip labels.
  static TextStyle routeStation({required Color color, bool bold = false}) =>
      GoogleFonts.interTight(
        color: color,
        fontSize: bold ? 14 : 13,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
        letterSpacing: -0.005 * (bold ? 14 : 13),
        height: 16 / (bold ? 14 : 13),
      );

  /// Route preview event line ("→ 3:00 PM Anna · Mitte · leave by 2:45").
  static TextStyle routeEvent({required Color color, FontWeight? weight}) =>
      GoogleFonts.interTight(
        color: color,
        fontSize: 13,
        fontWeight: weight ?? FontWeight.w500,
        letterSpacing: 0.01 * 13,
        height: 14 / 13,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Splash: huge "glance" wordmark.
  static TextStyle splashWordmark({required Color color}) =>
      GoogleFonts.interTight(
        color: color,
        fontSize: 144,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.05 * 144,
        height: 0.85,
      );

  /// Splash: italic serif tagline.
  static TextStyle splashTagline() => GoogleFonts.instrumentSerif(
        color: FamilyPalette.textSecondary,
        fontSize: 24,
        fontStyle: FontStyle.italic,
        letterSpacing: -0.005 * 24,
        height: 30 / 24,
      );

  /// Splash: "reaching BVG · loading your morning".
  static TextStyle splashLoading() => GoogleFonts.geistMono(
        color: FamilyPalette.textTertiary,
        fontSize: 11,
        letterSpacing: 0.04 * 11,
        height: 14 / 11,
      );

  /// Splash: lower caps-tracked version/locale line.
  static TextStyle splashVersion() => GoogleFonts.inter(
        color: FamilyPalette.textTertiary,
        fontSize: 10,
        letterSpacing: 0.16 * 10,
        height: 12 / 10,
      );

  /// Settings: eyebrow label on content panes ("DISPLAY", "WEATHER").
  static TextStyle settingsEyebrow({required Color color}) => GoogleFonts.inter(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.18 * 14,
        height: 18 / 14,
      );

  /// Settings: big page title ("How it looks").
  static TextStyle settingsTitle() => GoogleFonts.interTight(
        color: FamilyPalette.textPrimary,
        fontSize: 56,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.03 * 56,
        height: 1.0,
      );

  /// Settings: italic page subtitle.
  static TextStyle settingsSubtitle() => GoogleFonts.instrumentSerif(
        color: FamilyPalette.textSecondary,
        fontSize: 20,
        fontStyle: FontStyle.italic,
        letterSpacing: -0.005 * 20,
        height: 26 / 20,
      );

  /// Settings: the left "Settings" wordmark.
  static TextStyle settingsSidebarTitle() => GoogleFonts.interTight(
        color: FamilyPalette.textPrimary,
        fontSize: 52,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.03 * 52,
        height: 1.0,
      );

  /// Settings: subtitle under the "Settings" sidebar title.
  static TextStyle settingsSidebarTagline() => GoogleFonts.instrumentSerif(
        color: FamilyPalette.textSecondary,
        fontSize: 16,
        fontStyle: FontStyle.italic,
        height: 20 / 16,
      );

  /// Settings: nav list item title.
  static TextStyle navTitle({required bool active}) => GoogleFonts.interTight(
        color:
            active ? FamilyPalette.textPrimary : FamilyPalette.textSecondary,
        fontSize: 22,
        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
        letterSpacing: -0.015 * 22,
        height: 26 / 22,
      );

  /// Settings: nav list item subtitle.
  static TextStyle navSubtitle() => GoogleFonts.inter(
        color: FamilyPalette.textTertiary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 16 / 13,
      );

  /// Settings: section heading ("Theme", "Type scale", "Location").
  static TextStyle sectionTitle() => GoogleFonts.interTight(
        color: FamilyPalette.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 22,
        height: 26 / 22,
      );

  /// Settings: section description underneath the heading.
  static TextStyle sectionDescription() => GoogleFonts.inter(
        color: FamilyPalette.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 18 / 14,
      );

  /// Button-style text inside chips (e.g. "Landscape").
  static TextStyle chipText({required bool active}) => GoogleFonts.inter(
        color: active
            ? FamilyPalette.textPrimary
            : FamilyPalette.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 18 / 14,
      );

  /// Transit switcher entries.
  static TextStyle switcherEntry({required bool active}) =>
      GoogleFonts.interTight(
        color: active ? FamilyPalette.textPrimary : FamilyPalette.textTertiary,
        fontSize: 14,
        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
        letterSpacing: 0.02 * 14,
        height: 18 / 14,
      );

  /// "Leave by" + time in the countdown supporting row.
  static TextStyle leaveByTime() => GoogleFonts.interTight(
        color: FamilyPalette.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 17,
        height: 1.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
