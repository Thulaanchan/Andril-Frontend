import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/colors/m2_colors.dart';
import '../../../../app/themes/shared_core/components/m2_background_scaffold.dart';
import '../../../../app/themes/shared_core/components/m2_buttons.dart';
import '../../../../app/themes/shared_core/spacing/m2_spacing.dart';
import '../../../../app/themes/shared_core/typography/m2_typography.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/auth_info_banner.dart';
import '../../widgets/auth_otp_input.dart';
import '../viewmodels/verification_viewmodel.dart';

/// Screen 05: Account Verification Screen.
///
/// Implements the finalized `05 Account_Verification.png` design:
/// - Top header with back button and centered badge icon with mail verification.
/// - "Verify Your Email" heading.
/// - "We've sent a 6-digit verification code to" subtitle.
/// - Masked email container (`yo***@example.com`).
/// - 6-digit OTP code input boxes.
/// - "Verify & Continue" primary action button.
/// - "Didn't receive code? Resend Code" with cooldown indicator.
/// - Bottom Security Notice banner.
class AccountVerificationScreen extends StatefulWidget {
  const AccountVerificationScreen({
    required this.email,
    super.key,
    this.viewModel,
    this.authRepository,
    this.onBack,
    this.onVerificationSuccess,
  });

  final String email;
  final VerificationViewModel? viewModel;
  final AuthRepository? authRepository;
  final VoidCallback? onBack;
  final ValueChanged<AuthUser>? onVerificationSuccess;

  @override
  State<AccountVerificationScreen> createState() =>
      _AccountVerificationScreenState();
}

class _AccountVerificationScreenState extends State<AccountVerificationScreen> {
  late final VerificationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ??
        VerificationViewModel(
          repository: widget.authRepository!,
          email: widget.email,
        );

    _viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _handleVerify() {
    _viewModel.verifyCode(
      onSuccess: (user) {
        if (!mounted) return;
        widget.onVerificationSuccess?.call(user);
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
              // Top Bar with Back Arrow and Mail Badge Icon
              AuthHeader(
                onBack: widget.onBack,
                centerBadge: Container(
                  width: 80.0,
                  height: 80.0,
                  decoration: BoxDecoration(
                    color: M2Colors.primaryTealSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: M2Colors.primaryTeal.withValues(alpha: 0.35),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: M2Colors.primaryTeal.withValues(alpha: 0.15),
                        blurRadius: 16.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      size: 42.0,
                      color: M2Colors.primaryTeal,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: M2Spacing.md),

              // Heading and Instructions
              const Text(
                'Verify Your Email',
                style: M2Typography.heroTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: M2Spacing.xs),
              const Text(
                "We've sent a 6-digit verification code to",
                style: M2Typography.heroSubtitle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: M2Spacing.xs),

              // Masked Target Email Address
              Text(
                _viewModel.maskedEmail,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  color: M2Colors.textPrimary,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: M2Spacing.xl),

              // Error Banner if present
              if (_viewModel.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: M2Spacing.md,
                    vertical: M2Spacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(M2Spacing.radiusMd),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 20.0,
                      ),
                      const SizedBox(width: M2Spacing.xs),
                      Expanded(
                        child: Text(
                          _viewModel.errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
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

              // 6-digit OTP Input Boxes
              AuthOtpInput(
                length: 6,
                enabled: !_viewModel.isLoading,
                onChanged: _viewModel.setCode,
                onCompleted: (_) => _handleVerify(),
              ),

              const SizedBox(height: M2Spacing.xl),

              // Primary "Verify & Continue" Action Button
              M2PrimaryButton(
                text: 'Verify & Continue',
                isLoading: _viewModel.isLoading,
                onPressed: _viewModel.canSubmit ? _handleVerify : null,
              ),

              const SizedBox(height: M2Spacing.lg),

              // Resend Code Row with Cooldown
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    "Didn't receive code? ",
                    style: TextStyle(
                      fontSize: 14.5,
                      color: M2Colors.textSecondary,
                    ),
                  ),
                  if (_viewModel.isResendCooldownActive)
                    Text(
                      'Resend in ${_viewModel.resendCooldownSeconds}s',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _viewModel.isResending
                          ? null
                          : () => _viewModel.resendCode(),
                      child: Text(
                        _viewModel.isResending ? 'Sending...' : 'Resend Code',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: M2Colors.primaryTeal,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: M2Spacing.xl),

              // Security Notice Banner
              const AuthInfoBanner(
                title: 'Security Notice',
                message:
                    'Never share your verification code with anyone. ANDRIL staff will never ask for your code.',
                icon: Icons.shield_outlined,
                iconColor: M2Colors.primaryTeal,
              ),

              const SizedBox(height: M2Spacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
