import 'package:flutter/material.dart';

import '../../../../app/themes/hobbies/hobbies_theme.dart';
import '../../../../app/themes/hobbies/hobbies_typography.dart';
import '../../../../app/themes/hobbies/painters/teal_wave_painter.dart';

/// Reusable base scaffold component for the ANDRIL Hobbies module.
///
/// Unifies the approved Material 3 Hobbies theme, soft mint canvas background,
/// and optional organic decorative wave header while supporting caller-provided
/// content, titles, and actions across future Hobbies screens (Home, Gallery,
/// Clubs, Map, Profile).
///
/// Architecture & Accessibility Notes:
/// - Enforces [HobbiesTheme.lightTheme] so all child widgets consume the approved
///   Hobbies Material 3 colorScheme, textTheme, and accessible button themes.
/// - The decorative wave is wrapped in [IgnorePointer] and [ExcludeSemantics] so it
///   never intercepts touches or interferes with screen readers.
/// - Does not implement application routing, bottom navigation bars, or cross-module
///   navigation shortcuts.
class AndrilHobbiesScaffold extends StatelessWidget {
  /// The primary content widget to display within the scaffold.
  final Widget body;

  /// Optional screen title displayed in the AppBar.
  final String? title;

  /// Whether to render the decorative teal wave header behind the screen content.
  final bool showWave;

  /// Optional action widgets displayed on the trailing side of the AppBar.
  final List<Widget>? actions;

  /// Nominal wave header height when [showWave] is true.
  final double waveHeight;

  /// Creates an [AndrilHobbiesScaffold].
  const AndrilHobbiesScaffold({
    super.key,
    required this.body,
    this.title,
    this.showWave = true,
    this.actions,
    this.waveHeight = TealWavePainter.defaultWaveHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: HobbiesTheme.lightTheme,
      child: Builder(
        builder: (BuildContext themedContext) {
          final ThemeData theme = Theme.of(themedContext);
          final bool hasAppBar = title != null || actions != null;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            extendBodyBehindAppBar: false,
            appBar: hasAppBar
                ? AppBar(
                    title: title != null
                        ? Text(
                            title!,
                            style: theme.appBarTheme.titleTextStyle ??
                                HobbiesTypography.screenTitle.copyWith(
                                  color: HobbiesTheme.textDark,
                                ),
                          )
                        : null,
                    actions: actions,
                    backgroundColor: theme.appBarTheme.backgroundColor,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                  )
                : null,
            body: Stack(
              children: <Widget>[
                // Decorative wave header positioned behind content
                if (showWave)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: waveHeight,
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: CustomPaint(
                          painter: TealWavePainter(waveHeight: waveHeight),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),

                // Main screen content area using built-in Scaffold & SafeArea geometry
                SafeArea(
                  top: !hasAppBar,
                  child: body,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
