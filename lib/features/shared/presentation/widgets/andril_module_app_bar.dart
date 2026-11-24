import 'package:flutter/material.dart';

import '../../../../app/themes/learning/learning_colors.dart';

/// Standardized top application bar for ANDRIL module surfaces.
///
/// Implements [PreferredSizeWidget] with official branding, module badge,
/// and optional caller-controlled search and notification action slots.
/// Enforces WCAG touch targets (>= 48dp) and responsive layout down to 320dp.
class AndrilModuleAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// Module brand title displayed in the pill badge (e.g. 'Learning').
  final String moduleName;

  /// Background colour of the module badge pill.
  final Color badgeColor;

  /// Text colour of the module badge pill.
  final Color badgeTextColor;

  /// Background canvas colour of the app bar.
  final Color backgroundColor;

  /// Foreground colour for action icons and text.
  final Color foregroundColor;

  /// Asset path for the official black ANDRIL wordmark logo.
  final String logoAssetPath;

  /// Optional callback invoked when the search action icon is tapped.
  /// If null, the search icon is not rendered.
  final VoidCallback? onSearchTap;

  /// Optional callback invoked when the notification action icon is tapped.
  /// If null, the notification icon is not rendered.
  final VoidCallback? onNotificationTap;

  /// Optional leading widget (e.g. a back button when navigated).
  final Widget? leading;

  /// Whether to automatically imply leading widget if [leading] is null.
  final bool automaticallyImplyLeading;

  /// Elevation of the app bar.
  final double elevation;

  /// Height of the app bar toolbar. Defaults to [kToolbarHeight] (56.0).
  final double height;

  /// Creates an [AndrilModuleAppBar].
  const AndrilModuleAppBar({
    super.key,
    this.moduleName = 'Learning',
    this.badgeColor = LearningColors.primary,
    this.badgeTextColor = Colors.white,
    this.backgroundColor = LearningColors.background,
    this.foregroundColor = LearningColors.heading,
    this.logoAssetPath = 'assets/branding/andril_black_logo.png',
    this.onSearchTap,
    this.onNotificationTap,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.elevation = 0.0,
    this.height = kToolbarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final List<Widget> actionWidgets = [];

    if (onSearchTap != null) {
      actionWidgets.add(
        Semantics(
          label: 'Search $moduleName',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search $moduleName',
            onPressed: onSearchTap,
            color: foregroundColor,
            iconSize: 24,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            splashRadius: 24,
          ),
        ),
      );
    }

    if (onNotificationTap != null) {
      actionWidgets.add(
        Semantics(
          label: 'Notifications',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: onNotificationTap,
            color: foregroundColor,
            iconSize: 24,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            splashRadius: 24,
          ),
        ),
      );
    }

    if (actionWidgets.isNotEmpty) {
      actionWidgets.add(const SizedBox(width: 8));
    }

    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      centerTitle: false,
      titleSpacing: leading == null && !automaticallyImplyLeading ? 16 : 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            logoAssetPath,
            height: 24,
            fit: BoxFit.contain,
            semanticLabel: 'ANDRIL Logo',
            errorBuilder: (context, error, stackTrace) => Text(
              'ANDRIL',
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              moduleName,
              style: TextStyle(
                color: badgeTextColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      actions: actionWidgets.isNotEmpty ? actionWidgets : null,
    );
  }
}
