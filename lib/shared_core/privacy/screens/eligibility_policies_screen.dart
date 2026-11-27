import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/colors/m2_colors.dart';
import '../../../../app/themes/shared_core/components/m2_background_scaffold.dart';
import '../../../../app/themes/shared_core/components/m2_buttons.dart';
import '../../../../app/themes/shared_core/spacing/m2_spacing.dart';
import '../domain/entities/eligibility_result.dart';
import '../domain/entities/gender_type.dart';
import '../domain/entities/policy_document.dart';
import '../domain/repositories/eligibility_repository.dart';
import '../viewmodels/eligibility_viewmodel.dart';

/// Screen 09: Eligibility & Policies Screen.
///
/// Implements the finalized `09 Eligibility & Policies Onboarding Screen.png` design:
/// - Top header with back button and centered "Eligibility & Policies" title.
/// - Hero illustration badge with checklist clipboard and shield.
/// - "Before You Continue" hero heading and welcoming subtitle.
/// - "Social is 18+ only" informational callout banner.
/// - Community Guidelines respect & safety checkmark card.
/// - Date of Birth selection with native date picker (calendar icon).
/// - Gender dropdown selection.
/// - Terms of Service agreement checkbox.
/// - Privacy Policy review checkbox.
/// - Primary "Continue" button with forward arrow.
/// - Handles HTTP 503 service unavailable with retry (Rule 04).
/// - Enforces minimum age 16 for module eligibility without deleting auth account (Rule 02).
class EligibilityPoliciesScreen extends StatefulWidget {
  const EligibilityPoliciesScreen({
    super.key,
    this.viewModel,
    this.repository,
    this.onBack,
    this.onEligibilityConfirmed,
  });

  final EligibilityViewModel? viewModel;
  final EligibilityRepository? repository;
  final VoidCallback? onBack;
  final ValueChanged<EligibilityResult>? onEligibilityConfirmed;

  @override
  State<EligibilityPoliciesScreen> createState() =>
      _EligibilityPoliciesScreenState();
}

class _EligibilityPoliciesScreenState extends State<EligibilityPoliciesScreen> {
  late final EligibilityViewModel _viewModel;
  late final TapGestureRecognizer _guidelinesRecognizer;
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ??
        EligibilityViewModel(
          repository: widget.repository!,
        );
    _viewModel.addListener(_onViewModelChanged);

    _guidelinesRecognizer = TapGestureRecognizer()
      ..onTap = () => _openPolicyDocument(
            PolicyDocument.communityGuidelines(
              languageCode: _viewModel.languageCode,
            ),
          );

    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _openPolicyDocument(
            PolicyDocument.termsOfService(
              languageCode: _viewModel.languageCode,
            ),
          );

    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openPolicyDocument(
            PolicyDocument.privacyPolicy(
              languageCode: _viewModel.languageCode,
            ),
          );
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _guidelinesRecognizer.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _openPolicyDocument(PolicyDocument document) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 32.0),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 48.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              // Title and Badges
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.title,
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F3E48),
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Version ${document.version} • Effective ${document.effectiveDate}',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7F5),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      document.languageCode.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: M2Colors.primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Summary card
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  document.summary,
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: Color(0xFF334155),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 12.0),

              // Official URL link
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 14.0,
                    color: M2Colors.primaryTeal,
                  ),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      document.url,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: M2Colors.primaryTeal,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Full content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    document.content,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),

              // Close button
              M2PrimaryButton(
                text: 'Close',
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDateOfBirth(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _viewModel.dateOfBirth ?? DateTime(now.year - 20, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Your Date of Birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: M2Colors.primaryTeal,
              onPrimary: Colors.white,
              onSurface: M2Colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _viewModel.setDateOfBirth(picked);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _handleContinue() {
    _viewModel.submitEligibility(
      onSuccess: (result) {
        if (!mounted) return;
        widget.onEligibilityConfirmed?.call(result);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return M2BackgroundScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: M2Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar with Back Arrow and Title
              SizedBox(
                height: 48.0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (widget.onBack != null)
                      Positioned(
                        left: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: M2Colors.primaryTeal,
                            size: 24.0,
                          ),
                          onPressed: widget.onBack,
                          tooltip: 'Back',
                        ),
                      ),
                    const Center(
                      child: Text(
                        'Eligibility & Policies',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F3E48),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: M2Spacing.sm),

              // Checklist Clipboard and Shield Illustration Badge
              Center(
                child: Container(
                  width: 96.0,
                  height: 96.0,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: M2Colors.primaryTeal.withValues(alpha: 0.12),
                        blurRadius: 18.0,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 52.0,
                        color: M2Colors.primaryTeal,
                      ),
                      Positioned(
                        right: 14.0,
                        bottom: 14.0,
                        child: Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0D9488),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            size: 18.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: M2Spacing.md),

              // Hero Titles
              const Text(
                'Before You Continue',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF0A343D),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: M2Spacing.xs),
              const Text(
                'A few important details to keep you safe and welcoming.',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D4B54),
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: M2Spacing.md),

              // Social 18+ Callout Banner
              Container(
                padding: const EdgeInsets.all(M2Spacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F5).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(M2Spacing.radiusLg),
                  border: Border.all(
                    color: const Color(0xFF99F6E4),
                    width: 1.2,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 28.0,
                      color: Color(0xFF0D9488),
                    ),
                    SizedBox(width: M2Spacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Social is 18+ only',
                            style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F3E48),
                            ),
                          ),
                          SizedBox(height: 2.0),
                          Text(
                            'Under 18? You can still explore Learning and Hobbies.',
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF24525D),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: M2Spacing.sm),

              // Community Guidelines card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: M2Spacing.md,
                  vertical: M2Spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(M2Spacing.radiusMd),
                  border: Border.all(color: const Color(0xFFCCFBF1)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 20.0,
                      color: Color(0xFF0D9488),
                    ),
                    const SizedBox(width: M2Spacing.sm),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Our community values respect and safety. ',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF334155),
                          ),
                          children: [
                            TextSpan(
                              text: 'Community Guidelines',
                              recognizer: _guidelinesRecognizer,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0D9488),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: M2Spacing.md),

              // Error / 503 Service Unavailable Banner
              if (_viewModel.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(M2Spacing.md),
                  decoration: BoxDecoration(
                    color: _viewModel.isServiceUnavailable
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(M2Spacing.radiusMd),
                    border: Border.all(
                      color: _viewModel.isServiceUnavailable
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _viewModel.isServiceUnavailable
                            ? Icons.warning_amber_rounded
                            : Icons.error_outline_rounded,
                        color: _viewModel.isServiceUnavailable
                            ? const Color(0xFFD97706)
                            : const Color(0xFFDC2626),
                        size: 22.0,
                      ),
                      const SizedBox(width: M2Spacing.xs),
                      Expanded(
                        child: Text(
                          _viewModel.errorMessage!,
                          style: TextStyle(
                            color: _viewModel.isServiceUnavailable
                                ? const Color(0xFF92400E)
                                : const Color(0xFF991B1B),
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: M2Spacing.md),
              ],

              // Date of Birth Section
              const Text(
                'Date of Birth',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F3E48),
                ),
              ),
              const SizedBox(height: M2Spacing.xs),
              InkWell(
                onTap: _viewModel.isLoading ? null : () => _pickDateOfBirth(context),
                borderRadius: BorderRadius.circular(M2Spacing.radiusMd),
                child: Container(
                  height: 52.0,
                  padding: const EdgeInsets.symmetric(horizontal: M2Spacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(M2Spacing.radiusMd),
                    border: Border.all(
                      color: _viewModel.isUnder16
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _viewModel.dateOfBirth != null
                              ? _formatDate(_viewModel.dateOfBirth!)
                              : 'Select your date of birth',
                          style: TextStyle(
                            fontSize: 14.5,
                            color: _viewModel.dateOfBirth != null
                                ? M2Colors.textPrimary
                                : M2Colors.textMuted,
                            fontWeight: _viewModel.dateOfBirth != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 20.0,
                        color: M2Colors.primaryTeal,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: M2Spacing.md),

              // Gender Section
              const Text(
                'Gender',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F3E48),
                ),
              ),
              const SizedBox(height: M2Spacing.xs),
              Container(
                height: 52.0,
                padding: const EdgeInsets.symmetric(horizontal: M2Spacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(M2Spacing.radiusMd),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    width: 1.2,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<GenderType>(
                    value: _viewModel.gender,
                    hint: const Text(
                      'Select your gender',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: M2Colors.textMuted,
                      ),
                    ),
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: M2Colors.primaryTeal,
                    ),
                    items: GenderType.values.map((type) {
                      return DropdownMenuItem<GenderType>(
                        value: type,
                        child: Text(
                          type.displayLabel,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: M2Colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _viewModel.isLoading
                        ? null
                        : (val) {
                            if (val != null) _viewModel.setGender(val);
                          },
                  ),
                ),
              ),

              const SizedBox(height: M2Spacing.lg),

              // Terms of Service Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24.0,
                    height: 24.0,
                    child: Checkbox(
                      value: _viewModel.termsAccepted,
                      activeColor: M2Colors.primaryTeal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      onChanged: _viewModel.isLoading
                          ? null
                          : (val) => _viewModel.setTermsAccepted(val ?? false),
                    ),
                  ),
                  const SizedBox(width: M2Spacing.sm),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'I agree to the ',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF334155),
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            recognizer: _termsRecognizer,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D9488),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: M2Spacing.xs),

              // Privacy Policy Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24.0,
                    height: 24.0,
                    child: Checkbox(
                      value: _viewModel.privacyAccepted,
                      activeColor: M2Colors.primaryTeal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      onChanged: _viewModel.isLoading
                          ? null
                          : (val) => _viewModel.setPrivacyAccepted(val ?? false),
                    ),
                  ),
                  const SizedBox(width: M2Spacing.sm),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'I have reviewed the ',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF334155),
                        ),
                        children: [
                          TextSpan(
                            text: 'Privacy Policy',
                            recognizer: _privacyRecognizer,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D9488),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: M2Spacing.xl),

              // Primary "Continue" Button
              M2PrimaryButton(
                text: 'Continue',
                isLoading: _viewModel.isLoading,
                onPressed: _viewModel.canSubmit ? _handleContinue : null,
              ),

              const SizedBox(height: M2Spacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
