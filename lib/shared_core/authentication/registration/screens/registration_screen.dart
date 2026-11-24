import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/colors/m2_colors.dart';
import '../../../../app/themes/shared_core/components/m2_background_scaffold.dart';
import '../../../../app/themes/shared_core/components/m2_buttons.dart';
import '../../../../app/themes/shared_core/spacing/m2_spacing.dart';
import '../../../../app/themes/shared_core/typography/m2_typography.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/onboarding_auth_repository.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/google_sign_in_button.dart';
import '../viewmodels/registration_viewmodel.dart';

/// Screen 04: Email Registration Screen.
///
/// Implements the finalized `04 Email Registration.png` design:
/// - Top header with back navigation and ANDRIL logo emblem.
/// - "Create Account" heading and multi-space subtitle.
/// - Email, password, and confirm password form fields.
/// - Password visibility toggling.
/// - "Create Account" primary button.
/// - "OR" divider.
/// - "Continue with Google" secondary button.
/// - "Already have an account? Log In" navigation link.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({
    super.key,
    this.viewModel,
    this.authRepository,
    this.onBack,
    this.onNavigateToLogin,
    this.onVerificationRequired,
    this.onRegistrationSuccess,
  });

  final RegistrationViewModel? viewModel;
  final OnboardingAuthRepository? authRepository;
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToLogin;
  final ValueChanged<String>? onVerificationRequired;
  final ValueChanged<AuthUser>? onRegistrationSuccess;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  late final RegistrationViewModel _viewModel;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ??
        RegistrationViewModel(
          repository: widget.authRepository!,
        );

    _emailController = TextEditingController(text: _viewModel.email);
    _passwordController = TextEditingController(text: _viewModel.password);
    _confirmPasswordController =
        TextEditingController(text: _viewModel.confirmPassword);

    _viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _handleRegistration() {
    _viewModel.register(
      onSuccess: (user) {
        if (!mounted) return;
        widget.onRegistrationSuccess?.call(user);
      },
      onVerificationRequired: (email) {
        if (!mounted) return;
        widget.onVerificationRequired?.call(email);
      },
    );
  }

  void _handleGoogleSignIn() {
    _viewModel.continueWithGoogle(
      onSuccess: (user) {
        if (!mounted) return;
        widget.onRegistrationSuccess?.call(user);
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
              // Top Header with Back Navigation and ANDRIL Emblem
              AuthHeader(
                onBack: widget.onBack,
                showLogoEmblem: true,
                emblemSize: 76.0,
              ),

              const SizedBox(height: M2Spacing.sm),

              // Title and Subtitle
              const Text(
                'Create Account',
                style: M2Typography.heroTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: M2Spacing.xs),
              const Text(
                'Start your journey with one secure account.',
                style: M2Typography.heroSubtitle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: M2Spacing.lg),

              // Error banner if any
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
                textInputAction: TextInputAction.next,
                errorText: _viewModel.emailError,
                enabled: !_viewModel.isLoading && !_viewModel.isGoogleLoading,
                onChanged: _viewModel.setEmail,
              ),

              const SizedBox(height: M2Spacing.md),

              // Password Field
              AuthTextField(
                label: 'Password',
                hintText: 'Create a password',
                controller: _passwordController,
                leadingIcon: Icons.lock_outline_rounded,
                obscureText: !_viewModel.isPasswordVisible,
                textInputAction: TextInputAction.next,
                errorText: _viewModel.passwordError,
                enabled: !_viewModel.isLoading && !_viewModel.isGoogleLoading,
                onChanged: _viewModel.setPassword,
                trailing: IconButton(
                  icon: Icon(
                    _viewModel.isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: M2Colors.primaryTeal,
                    size: 20.0,
                  ),
                  onPressed: _viewModel.togglePasswordVisibility,
                  tooltip: _viewModel.isPasswordVisible
                      ? 'Hide password'
                      : 'Show password',
                ),
              ),

              const SizedBox(height: M2Spacing.md),

              // Confirm Password Field
              AuthTextField(
                label: 'Confirm Password',
                hintText: 'Re-enter your password',
                controller: _confirmPasswordController,
                leadingIcon: Icons.lock_outline_rounded,
                obscureText: !_viewModel.isConfirmPasswordVisible,
                textInputAction: TextInputAction.done,
                errorText: _viewModel.confirmPasswordError,
                enabled: !_viewModel.isLoading && !_viewModel.isGoogleLoading,
                onChanged: _viewModel.setConfirmPassword,
                onSubmitted: (_) => _handleRegistration(),
                trailing: IconButton(
                  icon: Icon(
                    _viewModel.isConfirmPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: M2Colors.primaryTeal,
                    size: 20.0,
                  ),
                  onPressed: _viewModel.toggleConfirmPasswordVisibility,
                  tooltip: _viewModel.isConfirmPasswordVisible
                      ? 'Hide password'
                      : 'Show password',
                ),
              ),

              const SizedBox(height: M2Spacing.md),

              // Terms and Privacy Agreement Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24.0,
                    height: 24.0,
                    child: Checkbox(
                      value: _viewModel.termsAgreed,
                      activeColor: M2Colors.primaryTeal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      onChanged: (_viewModel.isLoading || _viewModel.isGoogleLoading)
                          ? null
                          : (val) => _viewModel.setTermsAgreed(val ?? false),
                    ),
                  ),
                  const SizedBox(width: M2Spacing.sm),
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'I agree to the ',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: M2Colors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: M2Colors.primaryTeal,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: M2Colors.primaryTeal,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: M2Spacing.lg),

              // Primary "Create Account" Action Button
              M2PrimaryButton(
                text: 'Create Account',
                isLoading: _viewModel.isLoading,
                onPressed: _viewModel.canSubmit ? _handleRegistration : null,
              ),

              const SizedBox(height: M2Spacing.lg),

              // "OR" Divider
              Row(
                children: [
                  const Expanded(
                    child: Divider(color: Color(0xFFCBD5E1), thickness: 1.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: M2Spacing.md),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: M2Colors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: Color(0xFFCBD5E1), thickness: 1.0),
                  ),
                ],
              ),

              const SizedBox(height: M2Spacing.lg),

              // "Continue with Google" Button
              GoogleSignInButton(
                isLoading: _viewModel.isGoogleLoading,
                onPressed: (!_viewModel.isLoading && !_viewModel.isGoogleLoading)
                    ? _handleGoogleSignIn
                    : null,
              ),

              const SizedBox(height: M2Spacing.xl),

              // "Already have an account? Log In" Footer Link
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      fontSize: 14.5,
                      color: M2Colors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onNavigateToLogin,
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: M2Colors.primaryTeal,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: M2Spacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
