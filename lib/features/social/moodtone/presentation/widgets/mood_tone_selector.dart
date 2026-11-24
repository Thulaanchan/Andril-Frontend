import 'package:flutter/material.dart';
import 'package:andril_mobile/features/common/chat/domain/entities/chat_models.dart';

/// Exact reproduction of the Social HTML reference MoodTone panel:
/// - 2 rows × 5 columns layout
/// - Header with "MoodTone", "optional" hint, and collapse/expand caret (⌃ / ⌄)
/// - Vertical icon + label tiles with rounded corners
/// - Soft purple background, active purple selection border
class MoodToneSelector extends StatefulWidget {
  final MoodTone? selected;
  final ValueChanged<MoodTone?> onSelected;

  const MoodToneSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<MoodToneSelector> createState() => _MoodToneSelectorState();
}

class _MoodToneSelectorState extends State<MoodToneSelector> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('mood_selector'),
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 7),
      padding: const EdgeInsets.fromLTRB(9, 7, 9, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8FE),
        border: Border.all(color: const Color(0xFFEBD7ED)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A3C1B69),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header toggle matching HTML: <button id="moodHead" class="mood-head">
          InkWell(
            key: const Key('mood_head_toggle'),
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text(
                        'MoodTone',
                        style: TextStyle(
                          color: Color(0xFF2F1267),
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'optional',
                        style: TextStyle(
                          color: Color(0xFFA87CAD),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _expanded ? '⌃' : '⌄',
                    style: const TextStyle(
                      color: Color(0xFF2F1267),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2-row × 5-column grid matching reference HTML
          if (_expanded) ...[const SizedBox(height: 6), _buildMoodGrid()],
        ],
      ),
    );
  }

  Widget _buildMoodGrid() {
    // Exactly 10 tones in 2 rows of 5
    final tones = socialMoodTones.take(10).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < 5; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: _MoodTile(
                  tone: tones[i],
                  selected: widget.selected?.id == tones[i].id,
                  onTap: () => widget.onSelected(
                    widget.selected?.id == tones[i].id ? null : tones[i],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            for (var i = 5; i < 10 && i < tones.length; i++) ...[
              if (i > 5) const SizedBox(width: 4),
              Expanded(
                child: _MoodTile(
                  tone: tones[i],
                  selected: widget.selected?.id == tones[i].id,
                  onTap: () => widget.onSelected(
                    widget.selected?.id == tones[i].id ? null : tones[i],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MoodTile extends StatelessWidget {
  final MoodTone tone;
  final bool selected;
  final VoidCallback onTap;

  const _MoodTile({
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${tone.label} MoodTone',
      child: Material(
        color: selected ? const Color(0xFFEBDBFF) : const Color(0xFFFFFAFD),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('tone_${tone.id}'),
          onTap: onTap,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? const Color(0xFF7432C8)
                    : const Color(0xFFEAD7EF),
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tone.emoji,
                  style: const TextStyle(fontSize: 20, height: 1.1),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tone.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected
                          ? const Color(0xFF35106E)
                          : const Color(0xFF35116C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
