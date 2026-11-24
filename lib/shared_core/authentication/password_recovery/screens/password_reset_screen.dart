import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/colors/m2_colors.dart';
import '../../../../app/themes/shared_core/components/m2_background_scaffold.dart';
import '../../../../app/themes/shared_core/components/m2_buttons.dart';
import '../../../../app/themes/shared_core/spacing/m2_spacing.dart';
import '../../../../app/themes/shared_core/typography/m2_typography.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/auth_info_banner.dart';
import '../../widgets/auth_text_field.dart';
import '../viewmodels/password_reset_viewmodel.dart';

/// Screen 08: Create New Password Screen.
///
/// Implements the finalized `08 Password_Reset.png` design:
/// - Top header with back button and centered circular lock badge icon.
/// - "Create New Password" heading.
/// - "Choose a new password for your account." subtitle.
/// - "New password" and "Confirm new password" inputs with visibility toggles.
/// - Password policy guidance banner.
/// - "Update Password" primary action button.
/// - Handles invalid or expired recovery session without silent fallback.
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({
    super.key,
    this.viewModel,
    this.authRepository,
    this.recoveryToken,
    this.onBackToLogin,
    this.onPasswordResetSuccess,
  });

  final PasswordResetViewModel? viewModel;
  final AuthRepository? authRepository;
  final String? recoveryToken;
  final VoidCallback? onBackToLogin;
  final VoidCallback? onPasswordResetSuccess;

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  late final PasswordResetViewModel _viewModel;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ??
        PasswordResetViewModel(
          repository: widget.authRepository!,
          recoveryToken: widget.recoveryToken,
        );

    _newPasswordController =
        TextEditingController(text: _viewModel.newPassword);
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
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _handleUpdatePassword() {
    _viewModel.submitPasswordReset(
      onSuccess: () {
        if (!mounted) return;
        widget.onPasswordResetSuccess?.call();
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
              // Top Bar with Back Arrow and Lock Badge Icon
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
                      Icons.lock_outline_rounded,
                      size: 40.0,
                      color: M2Colors.primaryTeal,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: M2Spacing.md),

              // Title and Subtitle
              const Text(
                'Create New Password',
                style: M2Typography.heroTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: M2Spacing.xs),
              const Text(
                'Choose a new password for your account.',
                style: M2Typography.heroSubtitle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: M2Spacing.lg),

              // Success confirmation banner
              if (_viewModel.isSuccess) ...[
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
                          'Your password has been updated successfully.',
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
                const SizedBox(height: M2Spacing.lg),
              ],

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

              // New Password Input Field
              AuthTextField(
                label: 'New password',
                hintText: 'Enter a new password',
                controller: _newPasswordController,
                leadingIcon: Icons.lock_outline_rounded,
                obscureText: !_viewModel.isPasswordVisible,
                textInputAction: TextInputAction.next,
                errorText: _viewModel.newPasswordError,
                enabled: !_viewModel.isLoading && !_viewModel.isSuccess,
                onChanged: _viewModel.setNewPassword,
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

              // Confirm New Password Input Field
              AuthTextField(
                label: 'Confirm new password',
                hintText: 'Re-enter new password',
                controller: _confirmPasswordController,
                leadingIcon: Icons.lock_outline_rounded,
                obscureText: !_viewModel.isConfirmPasswordVisible,
                textInputAction: TextInputAction.done,
                errorText: _viewModel.confirmPasswordError,
                enabled: !_viewModel.isLoading && !_viewModel.isSuccess,
                onChanged: _viewModel.setConfirmPassword,
                onSubmitted: (_) => _handleUpdatePassword(),
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

              // Password Guidance Callout Banner
              const AuthInfoBanner(
                message:
                    'Use a strong and unique password. Follow the approved password policy.',
                icon: Icons.verified_user_outlined,
                iconColor: M2Colors.primaryTeal,
              ),

              const SizedBox(height: M2Spacing.xl),

              // Primary "Update Password" Action Button
              M2PrimaryButton(
                text: _viewModel.isSuccess ? 'Return to Log In' : 'Update Password',
                isLoading: _viewModel.isLoading,
                onPressed: _viewModel.isSuccess
                    ? widget.onBackToLogin
                    : (_viewModel.canSubmit ? _handleUpdatePassword : null),
              ),

              const SizedBox(height: M2Spacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
