import 'package:flutter/material.dart';

/// ANDRIL Social 2.0 Authoritative Design Tokens
/// Derived strictly from original source designs in `Screens-Social(New)`
/// (Social Frrame.png, S21-Banner.png, S1.png through S90)

class SocialPrototypeColors {
  SocialPrototypeColors._();

  // Brand & Action
  static const Color primaryPurple = Color(0xFF330099);
  static const Color actionPurple = Color(0xFF49156F);
  static const Color darkPurple = Color(0xFF2D1155);
  static const Color s01Purple = Color(0xFF1F1354);
  static const Color lavenderTint = Color(0xFFF2E8FF);
  static const Color copperAccent = Color(0xFFC47A44);
  static const Color copper = copperAccent;
  static const Color peachAccent = Color(0xFFFFE9D8);
  static const Color peach = peachAccent;
  static const Color peachPillActive = Color(0xFFF7E5D7);
  static const Color lightPeach = Color(0xFFFDEEE3);

  // Surfaces & Backgrounds
  static const Color creamBackground = Color(0xFFFAF7F2);
  static const Color contentBase = Color(0xFFFDFCF9);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF0E6DC);
  static const Color borderSubtle = Color(0xFFE8DFD5);
  static const Color segmentedTrack = Color(0xFFEFE6DC);

  // Text & Icons
  static const Color textPrimary = Color(0xFF2D1155);
  static const Color textSecondary = Color(0xFF5C4E63);
  static const Color textMuted = Color(0xFF7A665A);
  static const Color textCopper = Color(0xFFC47A44);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color iconInactive = Color(0xFF8E7E74);
  static const Color dividerColor = Color(0xFFEADBCE);
}

class SocialPrototypeGradients {
  SocialPrototypeGradients._();

  static const LinearGradient upperWaveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFAF1EA),
      Color(0xFFF5DDCD),
      Color(0xFFF6DBC7),
      Color(0xFFFCEFE4),
    ],
  );

  static const LinearGradient lowerWaveGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [
      Color(0xFFFAE8DB),
      Color(0xFFF3D4BE),
      Color(0xFFF0CDB4),
      Color(0xFFEDC7AD),
      Color(0xFFE9BFA2),
    ],
  );

  static const LinearGradient heroPurpleWave = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2B0C74),
      Color(0xFF1F1354),
    ],
  );

  static const LinearGradient heroCopperWave = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFD68A54),
      Color(0xFFC47A44),
      Color(0xFFB56A36),
    ],
  );
}

class SocialPrototypeDimens {
  SocialPrototypeDimens._();

  // Radii
  static const double radiusXs = 6.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusCard = 22.0;
  static const double radiusPill = 999.0;
  static const double radiusNavTop = 28.0;

  // Paddings
  static const double padHorizontal = 20.0;
  static const double padScreenTop = 16.0;
  static const double padCard = 16.0;

  // Heights & Sizes
  static const double buttonHeight = 52.0;
  static const double headerHeight = 60.0;
  static const double bottomNavHeight = 72.0;
}

class SocialPrototypeTypography {
  SocialPrototypeTypography._();

  static const TextStyle displayTitle = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w800,
    color: SocialPrototypeColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w700,
    color: SocialPrototypeColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w700,
    color: SocialPrototypeColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
    color: SocialPrototypeColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: SocialPrototypeColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: SocialPrototypeColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: SocialPrototypeColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle bodyRegular = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: SocialPrototypeColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: SocialPrototypeColors.textMuted,
    height: 1.4,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    color: SocialPrototypeColors.textInverse,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonLabelOutlined = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    color: SocialPrototypeColors.s01Purple,
    letterSpacing: 0.3,
  );
}

class SocialPrototypeTheme {
  SocialPrototypeTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: SocialPrototypeColors.creamBackground,
      colorScheme: const ColorScheme.light(
        primary: SocialPrototypeColors.actionPurple,
        secondary: SocialPrototypeColors.copperAccent,
        surface: SocialPrototypeColors.cardSurface,
        onPrimary: SocialPrototypeColors.textInverse,
        onSurface: SocialPrototypeColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: SocialPrototypeColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SocialPrototypeColors.actionPurple,
          foregroundColor: SocialPrototypeColors.textInverse,
          minimumSize:
              const Size.fromHeight(SocialPrototypeDimens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(SocialPrototypeDimens.radiusPill),
          ),
          textStyle: SocialPrototypeTypography.buttonLabel,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SocialPrototypeColors.actionPurple,
          minimumSize:
              const Size.fromHeight(SocialPrototypeDimens.buttonHeight),
          side: const BorderSide(
              color: SocialPrototypeColors.borderSubtle, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(SocialPrototypeDimens.radiusPill),
          ),
          textStyle: SocialPrototypeTypography.buttonLabelOutlined,
        ),
      ),
      cardTheme: CardThemeData(
        color: SocialPrototypeColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SocialPrototypeDimens.radiusCard),
          side: const BorderSide(
              color: SocialPrototypeColors.borderLight, width: 1),
        ),
      ),
    );
  }
}

class SocialPrototypeBackground extends StatelessWidget {
  final Widget child;
  final bool showWaves;

  const SocialPrototypeBackground({
    super.key,
    required this.child,
    this.showWaves = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SocialPrototypeColors.creamBackground,
      child: Stack(
        children: [
          if (showWaves)
            Positioned.fill(
              child: CustomPaint(
                painter: _SocialFrameWavesPainter(),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _SocialFrameWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Upper delicate wave
    final upperPaint = Paint()
      ..shader = SocialPrototypeGradients.upperWaveGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.4),
      )
      ..style = PaintingStyle.fill;

    final upperPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.16)
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.12,
        size.width * 0.35,
        size.height * 0.22,
        0,
        size.height * 0.18,
      )
      ..close();

    canvas.drawPath(upperPath, upperPaint);

    // Lower subtle wave
    final lowerPaint = Paint()
      ..shader = SocialPrototypeGradients.lowerWaveGradient.createShader(
        Rect.fromLTWH(0, size.height * 0.65, size.width, size.height * 0.35),
      )
      ..style = PaintingStyle.fill;

    final lowerPath = Path()
      ..moveTo(0, size.height * 0.85)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.80,
        size.width * 0.7,
        size.height * 0.89,
        size.width,
        size.height * 0.84,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(lowerPath, lowerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
