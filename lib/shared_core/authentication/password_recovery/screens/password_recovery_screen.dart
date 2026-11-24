import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/colors/m2_colors.dart';
import '../../../../app/themes/shared_core/components/m2_background_scaffold.dart';
import '../../../../app/themes/shared_core/components/m2_buttons.dart';
import '../../../../app/themes/shared_core/spacing/m2_spacing.dart';
import '../../../../app/themes/shared_core/typography/m2_typography.dart';
import '../../domain/repositories/onboarding_auth_repository.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/auth_info_banner.dart';
import '../../widgets/auth_text_field.dart';
import '../viewmodels/password_recovery_viewmodel.dart';

/// Screen 07: Password Recovery Request Screen.
///
/// Implements the finalized `07 Password_Recovery_Request.png` design:
/// - Top header with back button and centered circular key badge icon.
/// - "Forgot Password?" heading.
/// - "Enter your registered email address and we'll send you instructions to reset your password." subtitle.
/// - Email Address input field.
/// - Generic confirmation / privacy-preserving info banner.
/// - "Send Reset Link" primary action button.
/// - "Back to Log In" secondary outlined action button.
class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({
    super.key,
    this.viewModel,
    this.authRepository,
    this.onBackToLogin,
    this.onRecoverySubmitted,
  });

  final PasswordRecoveryViewModel? viewModel;
  final OnboardingAuthRepository? authRepository;
  final VoidCallback? onBackToLogin;
  final VoidCallback? onRecoverySubmitted;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  late final PasswordRecoveryViewModel _viewModel;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ??
        PasswordRecoveryViewModel(
          repository: widget.authRepository!,
        );

    _emailController = TextEditingController(text: _viewModel.email);
    _viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _emailController.dispose();
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _handleSendResetLink() {
    _viewModel.sendResetLink(
      onSuccess: () {
        if (!mounted) return;
        widget.onRecoverySubmitted?.call();
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
              // Top Bar with Back Arrow and Key Badge Icon
              AuthHeader(
                onBack: widget.onBackToLogin,
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
                      Icons.vpn_key_outlined,
                      size: 40.0,
                      color: M2Colors.primaryTeal,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: M2Spacing.md),

              // Title and Subtitle
              const Text(
                'Forgot Password?',
                style: M2Typography.heroTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: M2Spacing.xs),
              const Text(
                "Enter your registered email address and we'll send you instructions to reset your password.",
                style: M2Typography.heroSubtitle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: M2Spacing.lg),

              // Confirmation Banner when submitted
              if (_viewModel.isSubmitted) ...[
                Container(
                  padding: const EdgeInsets.all(M2Spacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(M2Spacing.radiusMd),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF059669),
                        size: 22.0,
                      ),
                      SizedBox(width: M2Spacing.xs),
                      Expanded(
                        child: Text(
                          'If an account exists for this email, recovery instructions have been sent.',
                          style: TextStyle(
                            color: Color(0xFF065F46),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: M2Spacing.md),
              ],

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

              // Email Address Field
              AuthTextField(
                label: 'Email Address',
                hintText: 'name@example.com',
                controller: _emailController,
                leadingIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                errorText: _viewModel.emailError,
                enabled: !_viewModel.isLoading,
                onChanged: _viewModel.setEmail,
                onSubmitted: (_) => _handleSendResetLink(),
              ),

              const SizedBox(height: M2Spacing.md),

              // Privacy Preserving Info Banner
              const AuthInfoBanner(
                message:
                    "If the address is registered, we'll send recovery instructions. Check your spam folder if you don't see it.",
                icon: Icons.info_outline_rounded,
                iconColor: M2Colors.primaryTeal,
              ),

              const SizedBox(height: M2Spacing.xl),

              // Primary "Send Reset Link" Button
              M2PrimaryButton(
                text: 'Send Reset Link',
                isLoading: _viewModel.isLoading,
                onPressed: _viewModel.canSubmit ? _handleSendResetLink : null,
              ),

              const SizedBox(height: M2Spacing.md),

              // Secondary "Back to Log In" Button
              M2SecondaryButton(
                text: 'Back to Log In',
                onPressed: widget.onBackToLogin,
              ),

              const SizedBox(height: M2Spacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
