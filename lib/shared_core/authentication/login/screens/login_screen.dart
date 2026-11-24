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
import '../../widgets/auth_text_field.dart';
import '../../widgets/google_sign_in_button.dart';
import '../viewmodels/login_viewmodel.dart';

/// Screen 06: Login and Google Sign-In Screen.
///
/// Implements the finalized `06 Login_and_Google_Sign-In.png` design:
/// - Top header with back button and ANDRIL logo emblem.
/// - "Log In" heading and welcome back subtitle.
/// - Email and Password fields.
/// - Right-aligned "Forgot Password?" link.
/// - "Log In" primary action button.
/// - "OR" divider.
/// - "Continue with Google" button.
/// - "One account. Three private module profiles." security callout.
/// - "Don't have an account? Create Account" navigation link.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.viewModel,
    this.authRepository,
    this.onBack,
    this.onNavigateToRegister,
    this.onNavigateToForgotPassword,
    this.onVerificationRequired,
    this.onLoginSuccess,
  });

  final LoginViewModel? viewModel;
  final AuthRepository? authRepository;
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToRegister;
  final VoidCallback? onNavigateToForgotPassword;
  final ValueChanged<String>? onVerificationRequired;
  final ValueChanged<AuthUser>? onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginViewModel _viewModel;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ??
        LoginViewModel(
          repository: widget.authRepository!,
        );

    _emailController = TextEditingController(text: _viewModel.email);
    _passwordController = TextEditingController(text: _viewModel.password);

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
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _handleLogin() {
    _viewModel.logIn(
      onSuccess: (user) {
        if (!mounted) return;
        widget.onLoginSuccess?.call(user);
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
        widget.onLoginSuccess?.call(user);
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
              // Top Header with Back Button and Logo Emblem
              AuthHeader(
                onBack: widget.onBack,
                showLogoEmblem: true,
                emblemSize: 76.0,
              ),

              const SizedBox(height: M2Spacing.sm),

              // Title and Subtitle
              const Text(
                'Log In',
                style: M2Typography.heroTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: M2Spacing.xs),
              const Text(
                'Welcome back. Continue your journey.',
                style: M2Typography.heroSubtitle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: M2Spacing.lg),

              // Error Banner if any
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
                hintText: 'Enter your password',
                controller: _passwordController,
                leadingIcon: Icons.lock_outline_rounded,
                obscureText: !_viewModel.isPasswordVisible,
                textInputAction: TextInputAction.done,
                errorText: _viewModel.passwordError,
                enabled: !_viewModel.isLoading && !_viewModel.isGoogleLoading,
                onChanged: _viewModel.setPassword,
                onSubmitted: (_) => _handleLogin(),
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

              const SizedBox(height: M2Spacing.xs),

              // "Forgot Password?" Right-aligned Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onNavigateToForgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: M2Spacing.xs,
                      vertical: M2Spacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: M2Colors.primaryTeal,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: M2Spacing.lg),

              // Primary "Log In" Button
              M2PrimaryButton(
                text: 'Log In',
                isLoading: _viewModel.isLoading,
                onPressed: _viewModel.canSubmit ? _handleLogin : null,
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

              const SizedBox(height: M2Spacing.lg),

              // Module Isolation / Privacy Notice
              const AuthInfoBanner(
                message: 'One account. Three private module profiles.',
                icon: Icons.lock_outline_rounded,
                iconColor: M2Colors.primaryTeal,
              ),

              const SizedBox(height: M2Spacing.lg),

              // "Don't have an account? Create Account" Link
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontSize: 14.5,
                      color: M2Colors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onNavigateToRegister,
                    child: const Text(
                      'Create Account',
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
