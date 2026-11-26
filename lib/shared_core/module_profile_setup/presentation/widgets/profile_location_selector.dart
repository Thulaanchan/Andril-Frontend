import 'package:flutter/material.dart';

/// Reusable city/region selection dropdown component.
class ProfileLocationSelector extends StatelessWidget {
  const ProfileLocationSelector({
    super.key,
    required this.selectedLocation,
    required this.placeholder,
    required this.helperText,
    required this.options,
    required this.primaryColor,
    required this.onChanged,
    required this.onClear,
  });

  final String selectedLocation;
  final String placeholder;
  final String helperText;
  final List<String> options;
  final Color primaryColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedLocation.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const Text(
          'Location (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),

        // Dropdown Selector Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: hasSelection ? selectedLocation : null,
              hint: Text(
                placeholder,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                ),
              ),
              icon: hasSelection
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: onClear,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    )
                  : const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B),
                    ),
              items: options.map((loc) {
                return DropdownMenuItem<String>(
                  value: loc,
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: loc == selectedLocation
                            ? primaryColor
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        loc,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: loc == selectedLocation
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  onChanged(val);
                }
              },
            ),
          ),
        ),

        // Privacy explanation
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 12,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                helperText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
