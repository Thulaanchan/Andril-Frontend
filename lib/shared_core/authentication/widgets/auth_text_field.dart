import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/colors/m2_colors.dart';
import '../../../../app/themes/shared_core/spacing/m2_spacing.dart';

/// ANDRIL Member-02 Reusable Form Input Field.
///
/// Features custom styling matching Screens 04, 06, 07:
/// - Rounded white container (radius 14)
/// - Leading icon
/// - Trailing widget (e.g. visibility toggle)
/// - Accessible error messaging
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.label,
    required this.hintText,
    required this.controller,
    super.key,
    this.leadingIcon,
    this.obscureText = false,
    this.trailing,
    this.keyboardType,
    this.textInputAction,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final IconData? leadingIcon;
  final bool obscureText;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Field Label
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: M2Colors.textPrimary,
          ),
        ),
        const SizedBox(height: M2Spacing.xs),

        // Input Container
        Container(
          height: 54.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(M2Spacing.radiusMd),
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFCBD5E1),
              width: errorText != null ? 1.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: M2Spacing.md),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: 20.0,
                  color: M2Colors.primaryTealLight,
                ),
                const SizedBox(width: M2Spacing.sm),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  enabled: enabled,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                    color: M2Colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),

        // Inline Error Message
        if (errorText != null) ...[
          const SizedBox(height: M2Spacing.xxs),
          Padding(
            padding: const EdgeInsets.only(left: M2Spacing.xs),
            child: Text(
              errorText!,
              style: const TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
