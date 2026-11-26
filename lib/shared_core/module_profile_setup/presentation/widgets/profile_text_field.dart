import 'package:flutter/material.dart';

/// Reusable display name text input component.
class ProfileTextField extends StatelessWidget {
  const ProfileTextField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.helperText,
    this.initialValue = '',
    this.errorText,
    required this.primaryColor,
    required this.onChanged,
  });

  final String label;
  final String placeholder;
  final String helperText;
  final String initialValue;
  final String? errorText;
  final Color primaryColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),

        // Text Field
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: errorText != null
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: errorText != null
                    ? const Color(0xFFDC2626)
                    : primaryColor,
                width: 1.5,
              ),
            ),
          ),
        ),

        // Supporting description or error
        const SizedBox(height: 6),
        if (errorText != null)
          Text(
            errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Text(
            helperText,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
      ],
    );
  }
}
