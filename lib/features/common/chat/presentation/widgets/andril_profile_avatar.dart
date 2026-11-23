import 'package:flutter/material.dart';
import 'package:andril_mobile/features/common/chat/domain/module_config.dart';

/// Clean, module-themed circular profile avatar widget.
///
/// Ensures:
/// 1. Perfect circular clipping using [ClipOval] with [BoxFit.cover].
/// 2. Seamless visual integration with the module header background.
/// 3. Crisp border matching the approved module palette:
///    - Learning: Blue #7B9EFA (matches HTML reference)
///    - Hobbies: Green #66D49A (matches HTML reference)
///    - Social: Soft Lilac #B779D5 (matches HTML reference, replaces #C47A44)
/// 4. Harmonious background fill matching the approved module palette:
///    - Learning: Soft Blue #E7EEFF
///    - Hobbies: Soft Mint #E6FBF5
///    - Social: Soft Lilac/Pink #FCEBF7
/// 5. Automatically uses clean transparent-background assets when available
///    to eliminate baked-in asymmetrical white fringes or opaque canvas boxes.
class AndrilProfileAvatar extends StatelessWidget {
  final String avatarAsset;
  final double size;
  final AndrilModuleType moduleType;
  final Color? borderColor;
  final Color? backgroundColor;
  final double borderWidth;
  final String fallbackInitial;

  const AndrilProfileAvatar({
    super.key,
    required this.avatarAsset,
    required this.moduleType,
    this.size = 44.0,
    this.borderColor,
    this.backgroundColor,
    this.borderWidth = 2.0,
    this.fallbackInitial = '?',
  });

  /// Approved border color per module.
  static Color defaultBorderColor(AndrilModuleType type) {
    switch (type) {
      case AndrilModuleType.learning:
        return const Color(0xFF7B9EFA);
      case AndrilModuleType.hobbies:
        return const Color(0xFF66D49A);
      case AndrilModuleType.social:
        return const Color(0xFFB779D5);
    }
  }

  /// Approved background fill per module.
  static Color defaultBackgroundColor(AndrilModuleType type) {
    switch (type) {
      case AndrilModuleType.learning:
        return const Color(0xFFE7EEFF);
      case AndrilModuleType.hobbies:
        return const Color(0xFFE6FBF5);
      case AndrilModuleType.social:
        return const Color(0xFFFCEBF7);
    }
  }

  /// Resolves avatar assets to transparent/cleaned variants when available,
  /// preserving the original files while eliminating baked-in fringe artifacts.
  static String resolveAsset(String asset) {
    if (asset == 'assets/profile/aira_avatar.png') {
      return 'assets/profile/aira_avatar_transparent.png';
    }
    if (asset == 'assets/profile/nila_avatar.png') {
      return 'assets/profile/nila_avatar_transparent.png';
    }
    if (asset == 'assets/profile/ava_avatar.webp') {
      return 'assets/profile/ava_avatar_clean.png';
    }
    return asset;
  }

  @override
  Widget build(BuildContext context) {
    final borderCol = borderColor ?? defaultBorderColor(moduleType);
    final bgCol = backgroundColor ?? defaultBackgroundColor(moduleType);
    final resolved = resolveAsset(avatarAsset);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgCol,
        border: Border.all(color: borderCol, width: borderWidth),
      ),
      child: ClipOval(
        child: Image.asset(
          resolved,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            if (resolved != avatarAsset) {
              return Image.asset(
                avatarAsset,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (ctx, err, st) =>
                    _buildFallback(bgCol, borderCol),
              );
            }
            return _buildFallback(bgCol, borderCol);
          },
        ),
      ),
    );
  }

  Widget _buildFallback(Color bg, Color border) {
    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Text(
        fallbackInitial,
        style: TextStyle(
          color: border,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.45,
        ),
      ),
    );
  }
}
