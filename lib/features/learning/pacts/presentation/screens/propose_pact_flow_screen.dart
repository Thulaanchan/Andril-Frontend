import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../viewmodels/learning_pacts_viewmodel.dart';

/// Lightweight candidate partner model for the invitation selector in Step 2.
class PactPartnerCandidate {
  final String profileId;
  final String displayName;
  final String? avatarUrl;
  final String skillsToShare;
  final String wantsToLearn;

  const PactPartnerCandidate({
    required this.profileId,
    required this.displayName,
    this.avatarUrl,
    required this.skillsToShare,
    required this.wantsToLearn,
  });
}

/// Multi-step proposal screen matching specifications Q31_LUC-18:
/// - Step 1: Pact Details & Commitment Milestones
/// - Step 2: Invite Partner from eligible learning candidates
/// - Step 3: Review & Confirm with explicit mutual acceptance notice
class ProposePactFlowScreen extends StatefulWidget {
  final LearningPactsViewModel viewModel;
  final List<PactPartnerCandidate>? candidatePartners;
  final VoidCallback? onPactProposed;

  const ProposePactFlowScreen({
    super.key,
    required this.viewModel,
    this.candidatePartners,
    this.onPactProposed,
  });

  @override
  State<ProposePactFlowScreen> createState() => _ProposePactFlowScreenState();
}

class _ProposePactFlowScreenState extends State<ProposePactFlowScreen> {
  int _currentStep = 1;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _studyPlanController = TextEditingController();
  final TextEditingController _milestoneInputController =
      TextEditingController();
  final TextEditingController _partnerSearchController =
      TextEditingController();

  final List<String> _commitments = [];
  PactPartnerCandidate? _selectedPartner;
  bool _isSubmitting = false;

  late final List<PactPartnerCandidate> _availablePartners;

  @override
  void initState() {
    super.initState();
    _availablePartners =
        List.unmodifiable(widget.candidatePartners ?? const []);

    if (_availablePartners.isNotEmpty) {
      _selectedPartner = _availablePartners.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    _durationController.dispose();
    _studyPlanController.dispose();
    _milestoneInputController.dispose();
    _partnerSearchController.dispose();
    super.dispose();
  }

  void _addMilestone() {
    final text = _milestoneInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _commitments.add(text);
        _milestoneInputController.clear();
      });
    }
  }

  void _removeMilestone(int index) {
    setState(() {
      _commitments.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (_selectedPartner == null) return;

    setState(() => _isSubmitting = true);

    final success = await widget.viewModel.proposePact(
      title: _titleController.text.trim(),
      sharedGoal: _goalController.text.trim(),
      partnerProfileId: _selectedPartner!.profileId,
      partnerDisplayName: _selectedPartner!.displayName,
      partnerAvatarUrl: _selectedPartner!.avatarUrl,
      duration: _durationController.text.trim().isNotEmpty
          ? _durationController.text.trim()
          : null,
      studyPlan: _studyPlanController.text.trim().isNotEmpty
          ? _studyPlanController.text.trim()
          : null,
      commitmentTexts: _commitments,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        widget.onPactProposed?.call();
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('screen_propose_pact_flow'),
      backgroundColor: LearningColors.background,
      appBar: AppBar(
        title: Text(_stepTitle),
        backgroundColor: LearningColors.cardSurface,
        foregroundColor: LearningColors.heading,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepperHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildCurrentStepContent(),
              ),
            ),
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  String get _stepTitle {
    switch (_currentStep) {
      case 1:
        return 'Pact Details';
      case 2:
        return 'Invite Learning Partner';
      case 3:
      default:
        return 'Review & Confirm Pact';
    }
  }

  Widget _buildStepperHeader() {
    return Container(
      color: LearningColors.cardSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CREATE LEARNING PACT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: LearningColors.primary,
                ),
              ),
              Text(
                'STEP $_currentStep OF 3',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Row(
            children: [
              _buildStepIndicator(
                step: 1,
                label: '1 Pact Details',
                isActive: _currentStep == 1,
                isCompleted: _currentStep > 1,
              ),
              const SizedBox(width: 8.0),
              _buildStepIndicator(
                step: 2,
                label: '2 Invite Partner',
                isActive: _currentStep == 2,
                isCompleted: _currentStep > 2,
              ),
              const SizedBox(width: 8.0),
              _buildStepIndicator(
                step: 3,
                label: '3 Confirm',
                isActive: _currentStep == 3,
                isCompleted: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int step,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    final bgColor = isCompleted
        ? const Color(0xFFDCFCE7)
        : isActive
            ? LearningColors.primary
            : Colors.grey.shade200;

    final textColor = isCompleted
        ? const Color(0xFF15803D)
        : isActive
            ? Colors.white
            : LearningColors.secondaryText;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isCompleted) ...[
              const Icon(Icons.check, size: 14, color: Color(0xFF15803D)),
              const SizedBox(width: 4.0),
            ],
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Details();
      case 2:
        return _buildStep2Partner();
      case 3:
      default:
        return _buildStep3Review();
    }
  }

  // --- Step 1: Details ---
  Widget _buildStep1Details() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: LearningColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: const Row(
              children: [
                Icon(Icons.handshake_outlined,
                    size: 32, color: LearningColors.primary),
                SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Pact Details',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: LearningColors.heading,
                        ),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Define a collaborative study goal and agreed commitment milestones.',
                        style: TextStyle(
                          fontSize: 12,
                          color: LearningColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Title
          const Text(
            'Pact Title *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
          const SizedBox(height: 6.0),
          TextFormField(
            key: const ValueKey('input_pact_title'),
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'e.g., Build a Flutter project',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Pact title is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),

          // Goal
          const Text(
            'Shared Learning Goal *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
          const SizedBox(height: 6.0),
          TextFormField(
            key: const ValueKey('input_pact_goal'),
            controller: _goalController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g., Build and present a basic Flutter mobile app.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Shared goal is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),

          // Duration & Study Plan Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Duration',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: LearningColors.heading,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      key: const ValueKey('input_pact_duration'),
                      controller: _durationController,
                      decoration: InputDecoration(
                        hintText: '4 weeks',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Study Plan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: LearningColors.heading,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      key: const ValueKey('input_pact_study_plan'),
                      controller: _studyPlanController,
                      decoration: InputDecoration(
                        hintText: '3 days per week',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),

          // Commitments / Milestones
          const Text(
            'Commitment Milestones',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
          const SizedBox(height: 6.0),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('input_pact_commitment'),
                  controller: _milestoneInputController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Complete Chapter 3 exercises',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              SizedBox(
                height: 52.0,
                child: ElevatedButton(
                  key: const ValueKey('btn_add_pact_commitment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LearningColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: _addMilestone,
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
          if (_commitments.isNotEmpty) ...[
            const SizedBox(height: 12.0),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _commitments.length,
              itemBuilder: (ctx, idx) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: LearningColors.cardSurface,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            LearningColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: LearningColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          _commitments[idx],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _removeMilestone(idx),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // --- Step 2: Invite Partner ---
  Widget _buildStep2Partner() {
    final query = _partnerSearchController.text.trim().toLowerCase();
    final filtered = _availablePartners.where((p) {
      if (query.isEmpty) return true;
      return p.displayName.toLowerCase().contains(query) ||
          p.skillsToShare.toLowerCase().contains(query) ||
          p.wantsToLearn.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: LearningColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14.0),
          ),
          child: const Row(
            children: [
              Icon(Icons.person_add_alt_1_outlined,
                  size: 32, color: LearningColors.primary),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learn together. Grow together.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: LearningColors.heading,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      'Choose one eligible Learning partner to invite. The pact begins only after mutual acceptance.',
                      style: TextStyle(
                        fontSize: 12,
                        color: LearningColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),

        // Search Bar
        TextField(
          key: const ValueKey('input_search_partners'),
          controller: _partnerSearchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search Learning names or skills',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
        const SizedBox(height: 16.0),

        // Partner List
        const Text(
          'Suggested Learning Partners',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: LearningColors.heading,
          ),
        ),
        const SizedBox(height: 8.0),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (ctx, idx) {
            final p = filtered[idx];
            final isSelected = _selectedPartner?.profileId == p.profileId;

            return InkWell(
              key: ValueKey('card_select_partner_${p.profileId}'),
              onTap: () => setState(() => _selectedPartner = p),
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10.0),
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? LearningColors.primary.withValues(alpha: 0.05)
                      : LearningColors.cardSurface,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isSelected
                        ? LearningColors.primary
                        : Colors.black.withValues(alpha: 0.08),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          LearningColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        p.displayName[0],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: LearningColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                p.displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: LearningColors.heading,
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: const Text(
                                  'Learning only',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Can share: ${p.skillsToShare}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: LearningColors.secondaryText,
                            ),
                          ),
                          Text(
                            'Wants to learn: ${p.wantsToLearn}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: LearningColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? LearningColors.primary
                          : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- Step 3: Review & Confirm ---
  Widget _buildStep3Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // One last review Banner
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            children: [
              Icon(Icons.rate_review_outlined,
                  size: 32, color: LearningColors.primary),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'One last review',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: LearningColors.heading,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      'Check the proposed pact before inviting your partner. Nothing becomes active until both learners agree.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E40AF),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),

        // PACT DETAILS Card
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: LearningColors.cardSurface,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PACT DETAILS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: LearningColors.primary,
                ),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Pact title',
                style: TextStyle(
                  fontSize: 11,
                  color: LearningColors.secondaryText,
                ),
              ),
              Text(
                _titleController.text.trim(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Shared Learning Goal',
                style: TextStyle(
                  fontSize: 11,
                  color: LearningColors.secondaryText,
                ),
              ),
              Text(
                _goalController.text.trim(),
                style: const TextStyle(
                  fontSize: 13,
                  color: LearningColors.secondaryText,
                ),
              ),
              const SizedBox(height: 14.0),
              Row(
                children: [
                  if (_durationController.text.trim().isNotEmpty) ...[
                    const Icon(Icons.schedule,
                        size: 16, color: LearningColors.secondaryText),
                    const SizedBox(width: 6.0),
                    Text(
                      _durationController.text.trim(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: LearningColors.heading,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                  ],
                  if (_studyPlanController.text.trim().isNotEmpty) ...[
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: LearningColors.secondaryText),
                    const SizedBox(width: 6.0),
                    Text(
                      _studyPlanController.text.trim(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: LearningColors.heading,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),

        // SELECTED LEARNING PARTNER Card
        if (_selectedPartner != null)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: LearningColors.cardSurface,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SELECTED LEARNING PARTNER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: LearningColors.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Text(
                        'Learning only',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          LearningColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        _selectedPartner!.displayName[0],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: LearningColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPartner!.displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: LearningColors.heading,
                            ),
                          ),
                          Text(
                            'Skills to share: ${_selectedPartner!.skillsToShare}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: LearningColors.secondaryText,
                            ),
                          ),
                          Text(
                            'Wants to learn: ${_selectedPartner!.wantsToLearn}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: LearningColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 16.0),

        // Mutual Acceptance Notice Callout
        Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: Color(0xFF1D4ED8)),
              SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invitation requires mutual acceptance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      'Sending this invitation does not activate the pact. Your selected partner can review and accept or decline.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E3A8A),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      color: LearningColors.cardSurface,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (_currentStep > 1) ...[
            Expanded(
              child: SizedBox(
                height: 44.0,
                child: OutlinedButton(
                  key: ValueKey('btn_step${_currentStep}_back'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () => setState(() => _currentStep--),
                  child: const Text('Back'),
                ),
              ),
            ),
            const SizedBox(width: 12.0),
          ],
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 44.0,
              child: ElevatedButton(
                key: ValueKey(_currentStep == 3
                    ? 'btn_submit_propose_pact'
                    : 'btn_step${_currentStep}_continue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: _isSubmitting
                    ? null
                    : () {
                        if (_currentStep == 1) {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _currentStep = 2);
                          }
                        } else if (_currentStep == 2) {
                          if (_selectedPartner != null) {
                            setState(() => _currentStep = 3);
                          }
                        } else {
                          _handleSubmit();
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentStep == 1
                            ? 'Continue to Partner'
                            : _currentStep == 2
                                ? 'Review Invitation'
                                : 'Send Pact Invitation',
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
