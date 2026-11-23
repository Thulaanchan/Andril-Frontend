import 'package:flutter/material.dart';

import '../../../../app/themes/learning/learning_colors.dart';

/// Standardized error and retry card component for ANDRIL surfaces.
///
/// Displays a user-friendly error title, a safe error message without technical
/// jargon or raw stack traces, an error icon, and an optional retry action button.
/// Enforces WCAG touch targets (>= 48dp) and responsive layout across viewports (>= 320dp).
class ErrorRetryCard extends StatelessWidget {
  /// Header title for the error message (e.g. 'Unable to load data').
  final String title;

  /// User-facing description of the error.
  final String message;

  /// Optional callback invoked when the user taps the retry button.
  /// If null, the retry button is omitted.
  final VoidCallback? onRetry;

  /// Whether an asynchronous retry operation is currently in progress.
  /// When true, the retry button is disabled and displays a progress spinner.
  final bool isRetrying;

  /// Label displayed on the retry button in its default state.
  final String retryButtonText;

  /// Label displayed on the retry button while retrying.
  final String retryingText;

  /// Icon displayed in the header badge.
  final IconData icon;

  /// Colour of the error icon. Defaults to `#DC2626`.
  final Color? iconColor;

  /// Background colour of the card. Defaults to [LearningColors.cardSurface].
  final Color? backgroundColor;

  /// Border colour of the card. Defaults to `#FCA5A5`.
  final Color? borderColor;

  /// Text colour for the error title. Defaults to [LearningColors.heading].
  final Color? titleColor;

  /// Text colour for the error message. Defaults to [LearningColors.secondaryText].
  final Color? messageColor;

  /// Padding inside the card container.
  final EdgeInsetsGeometry padding;

  /// Optional external margin around the card container.
  final EdgeInsetsGeometry? margin;

  /// Creates an [ErrorRetryCard].
  const ErrorRetryCard({
    super.key,
    this.title = 'Unable to load data',
    this.message = 'An unexpected error occurred. Please try again.',
    this.onRetry,
    this.isRetrying = false,
    this.retryButtonText = 'Retry',
    this.retryingText = 'Retrying...',
    this.icon = Icons.error_outline_rounded,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.titleColor,
    this.messageColor,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor =
        backgroundColor ?? LearningColors.cardSurface;
    final effectiveBorderColor = borderColor ?? const Color(0xFFFCA5A5);
    final effectiveIconColor = iconColor ?? const Color(0xFFDC2626);
    final effectiveTitleColor = titleColor ?? LearningColors.heading;
    final effectiveMessageColor = messageColor ?? LearningColors.secondaryText;

    Widget cardContent = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: effectiveIconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 28,
              color: effectiveIconColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: effectiveTitleColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: effectiveMessageColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isRetrying ? null : onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      LearningColors.primary.withValues(alpha: 0.6),
                  disabledForegroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 0,
                  minimumSize: const Size(120, 48),
                ),
                child: isRetrying
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            retryingText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.refresh_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            retryButtonText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      container: true,
      liveRegion: true,
      label: '$title. $message',
      child: cardContent,
    );
  }
}
