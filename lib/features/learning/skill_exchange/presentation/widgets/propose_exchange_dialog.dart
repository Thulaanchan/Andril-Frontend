import 'package:flutter/material.dart';

import '../../../../../app/themes/learning/learning_colors.dart';
import '../../domain/entities/skill_exchange.dart';
import '../../domain/entities/skill_partner.dart';

/// Modal dialog for configuring and proposing a Skill Exchange.
///
/// Complies with DEC-20261120-LRN01-01 / DEC-M1-01 rules:
/// - Rejects identical offered and wanted skills.
/// - Validates unordered pair uniqueness against existing pending proposals.
/// - Does not fabricate ratings, XP, or automatic chat/connection permissions.
class ProposeExchangeDialog extends StatefulWidget {
  final SkillPartner partner;
  final List<String> userSkillsToShare;
  final List<SkillExchange> existingProposals;
  final void Function(String offeredSkill, String wantedSkill, String? note)
      onSubmit;

  const ProposeExchangeDialog({
    super.key,
    required this.partner,
    required this.userSkillsToShare,
    required this.existingProposals,
    required this.onSubmit,
  });

  @override
  State<ProposeExchangeDialog> createState() => _ProposeExchangeDialogState();
}

class _ProposeExchangeDialogState extends State<ProposeExchangeDialog> {
  late String _selectedOfferedSkill;
  late String _selectedWantedSkill;
  final TextEditingController _customOfferedController =
      TextEditingController();
  final TextEditingController _customWantedController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isCustomOffered = false;
  bool _isCustomWanted = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _selectedOfferedSkill = widget.userSkillsToShare.isNotEmpty
        ? widget.userSkillsToShare.first
        : '';

    final availableWanted = widget.partner.skillsOffered
        .where((s) => s.toLowerCase() != _selectedOfferedSkill.toLowerCase())
        .toList();

    _selectedWantedSkill = availableWanted.isNotEmpty
        ? availableWanted.first
        : (widget.partner.skillsOffered.isNotEmpty
            ? widget.partner.skillsOffered.first
            : '');

    if (_selectedOfferedSkill.isEmpty) {
      _isCustomOffered = true;
    }
    if (_selectedWantedSkill.isEmpty) {
      _isCustomWanted = true;
    }
  }

  @override
  void dispose() {
    _customOfferedController.dispose();
    _customWantedController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final offered = (_isCustomOffered
            ? _customOfferedController.text
            : _selectedOfferedSkill)
        .trim();
    final wanted =
        (_isCustomWanted ? _customWantedController.text : _selectedWantedSkill)
            .trim();

    if (offered.isEmpty || wanted.isEmpty) {
      setState(() {
        _validationError = 'Please specify both an offered and a wanted skill.';
      });
      return;
    }

    if (offered.toLowerCase() == wanted.toLowerCase()) {
      setState(() {
        _validationError =
            'An identical offered and wanted skill requires an approved overlap policy.';
      });
      return;
    }

    // Check pair guard against existing pending proposals
    final hasPendingConflict = widget.existingProposals.any((p) {
      if (p.status != SkillExchangeStatus.pending) return false;
      final samePair =
          (p.sender.learningProfileId == widget.partner.profileId) ||
              (p.recipient.learningProfileId == widget.partner.profileId);
      return samePair;
    });

    if (hasPendingConflict) {
      setState(() {
        _validationError =
            'A pending Skill Exchange already exists with this partner.';
      });
      return;
    }

    widget.onSubmit(
      offered,
      wanted,
      _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const ValueKey('dialog_propose_exchange'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      backgroundColor: LearningColors.cardSurface,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Propose Skill Exchange',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: LearningColors.heading,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('btn_dismiss_proposal_dialog'),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                'Partner: ${widget.partner.displayName}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: LearningColors.primary,
                ),
              ),

              const SizedBox(height: 16.0),

              if (_validationError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          _validationError!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),
              ],

              // Section 1: Skill You Offer
              const Text(
                'Skill You Will Teach (Your Offer):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 6.0),
              if (widget.userSkillsToShare.isNotEmpty && !_isCustomOffered)
                Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: [
                    ...widget.userSkillsToShare.map((skill) {
                      final isSelected = _selectedOfferedSkill == skill;
                      return ChoiceChip(
                        label: Text(skill),
                        selected: isSelected,
                        selectedColor:
                            LearningColors.primary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? LearningColors.primary
                              : LearningColors.heading,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedOfferedSkill = skill;
                              _validationError = null;
                            });
                          }
                        },
                      );
                    }),
                    ActionChip(
                      label: const Text('+ Other'),
                      onPressed: () {
                        setState(() {
                          _isCustomOffered = true;
                          _validationError = null;
                        });
                      },
                    ),
                  ],
                )
              else
                TextField(
                  key: const ValueKey('input_offered_skill'),
                  controller: _customOfferedController,
                  decoration: InputDecoration(
                    hintText: 'Enter skill you will teach...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    suffixIcon: widget.userSkillsToShare.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.list_rounded),
                            tooltip: 'Select from profile skills',
                            onPressed: () {
                              setState(() {
                                _isCustomOffered = false;
                              });
                            },
                          )
                        : null,
                  ),
                ),

              const SizedBox(height: 16.0),

              // Section 2: Skill You Want (Partner's Offer)
              Text(
                'Skill You Want from ${widget.partner.displayName}:',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 6.0),
              if (widget.partner.skillsOffered.isNotEmpty && !_isCustomWanted)
                Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: [
                    ...widget.partner.skillsOffered.map((skill) {
                      final isSelected = _selectedWantedSkill == skill;
                      return ChoiceChip(
                        label: Text(skill),
                        selected: isSelected,
                        selectedColor: Colors.amber.shade100,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.amber.shade900
                              : LearningColors.heading,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedWantedSkill = skill;
                              _validationError = null;
                            });
                          }
                        },
                      );
                    }),
                    ActionChip(
                      label: const Text('+ Other'),
                      onPressed: () {
                        setState(() {
                          _isCustomWanted = true;
                          _validationError = null;
                        });
                      },
                    ),
                  ],
                )
              else
                TextField(
                  key: const ValueKey('input_wanted_skill'),
                  controller: _customWantedController,
                  decoration: InputDecoration(
                    hintText: 'Enter skill you want to learn...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    suffixIcon: widget.partner.skillsOffered.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.list_rounded),
                            tooltip: 'Select from partner skills',
                            onPressed: () {
                              setState(() {
                                _isCustomWanted = false;
                              });
                            },
                          )
                        : null,
                  ),
                ),

              const SizedBox(height: 16.0),

              // Section 3: Optional proposal message
              const Text(
                'Proposal Message (Optional):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 6.0),
              TextField(
                key: const ValueKey('input_proposal_note'),
                controller: _noteController,
                maxLines: 2,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'e.g. Happy to exchange 1 hour weekly sessions.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),

              const SizedBox(height: 8.0),

              // Boundary Disclaimer
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: LearningColors.background,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: LearningColors.secondaryText,
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        'Proposals do not automatically connect accounts or activate chat without approved authorization.',
                        style: TextStyle(
                          fontSize: 10,
                          color: LearningColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18.0),

              // Action buttons
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    key: const ValueKey('btn_submit_exchange_proposal'),
                    onPressed: _handleSubmit,
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Send Proposal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LearningColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
