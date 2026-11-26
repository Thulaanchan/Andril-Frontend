import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable multiline "About Me" input component with live character counter.
///
/// Features:
/// - 100-character UI presentation limit matching finalized reference designs.
/// - Live counter displaying current length / limit (e.g. `0/100`).
/// - Multiline expansion (3 to 5 lines).
class ProfileAboutMeField extends StatelessWidget {
  const ProfileAboutMeField({
    super.key,
    required this.placeholder,
    this.initialValue = '',
    this.maxLength = 100,
    required this.primaryColor,
    required this.onChanged,
  });

  final String placeholder;
  final String initialValue;
  final int maxLength;
  final Color primaryColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label & Counter row
        Row(
          children: [
            const Expanded(
              child: Text(
                'About Me (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            Text(
              '${initialValue.length}/$maxLength',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Multiline Text Field
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
          maxLines: 4,
          minLines: 3,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF0F172A),
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
