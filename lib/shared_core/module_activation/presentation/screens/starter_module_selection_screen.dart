import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/colors/m2_colors.dart';
import '../../../../app/themes/shared_core/components/m2_background_scaffold.dart';
import '../../../../app/themes/shared_core/components/m2_buttons.dart';
import '../../../../app/themes/shared_core/spacing/m2_spacing.dart';
import '../../domain/entities/starter_selection_result.dart';
import '../../domain/repositories/starter_module_repository.dart';
import '../viewmodels/starter_module_viewmodel.dart';

/// Screen 10: Starter Module Selection Screen (No Logo).
///
/// Implements the finalized `Choose_Modules_No_Logo` design:
/// - "CHOOSE YOUR MODULES" header badge with back arrow.
/// - "Preview Tour" mode toggle pill.
/// - "Choose Your Path" hero heading and subtitle.
/// - 3-module carousel (Learning, Hobbies, Social).
/// - Distinct module branding (Learning: Blue, Hobbies: Green, Social: Purple).
/// - Social 18+ Age Verification Modal requirement.
/// - Module information banner: "Choose one module to get started."
/// - Selected module status indicator pill.
/// - Primary "Continue" button with forward arrow.
/// - Complies with Rule 05 (Starter selection is NOT lifecycle activation)
///   and Rule 06 (No lifecycle endpoints consumed).
class StarterModuleSelectionScreen extends StatefulWidget {
  const StarterModuleSelectionScreen({
    super.key,
    this.viewModel,
    this.repository,
    this.isSocialAuthorizedByServer = true,
    this.onBack,
    this.onStarterSelectionCompleted,
  });

  final StarterModuleViewModel? viewModel;
  final StarterModuleRepository? repository;
  final bool isSocialAuthorizedByServer;
  final VoidCallback? onBack;
  final ValueChanged<StarterSelectionResult>? onStarterSelectionCompleted;

  @override
  State<StarterModuleSelectionScreen> createState() =>
      _StarterModuleSelectionScreenState();
}

class _StarterModuleSelectionScreenState
    extends State<StarterModuleSelectionScreen> {
  late final StarterModuleViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ??
        StarterModuleViewModel(
          repository: widget.repository!,
          isSocialAuthorizedByServer: widget.isSocialAuthorizedByServer,
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

  void _handleContinue() {
    _viewModel.submitStarterSelection(
      onCompleted: (result) {
        if (!mounted) return;
        widget.onStarterSelectionCompleted?.call(result);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeModule = _viewModel.currentModule;
    final isSelected =
        _viewModel.selectedModuleIndex == _viewModel.currentIndex;

    return M2BackgroundScaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: M2Spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Navigation Bar
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
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: M2Spacing.md,
                              vertical: 5.0,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1).withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(M2Spacing.radiusPill),
                              border: Border.all(
                                color: const Color(0xFF99F6E4),
                                width: 1.0,
                              ),
                            ),
                            child: const Text(
                              'CHOOSE YOUR MODULES',
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: M2Spacing.xs),

                  // Preview Tour Pill Button
                  Center(
                    child: InkWell(
                      onTap: _viewModel.toggleTourMode,
                      borderRadius: BorderRadius.circular(M2Spacing.radiusPill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: M2Spacing.md,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(M2Spacing.radiusPill),
                          border: Border.all(
                            color: const Color(0xFF99F6E4),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6.0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _viewModel.isTourMode
                                  ? Icons.pause_circle_rounded
                                  : Icons.play_arrow_rounded,
                              size: 16.0,
                              color: const Color(0xFF0D9488),
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              _viewModel.isTourMode
                                  ? 'Pause Tour'
                                  : 'Preview Tour',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF134E4A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: M2Spacing.sm),

                  // Hero Headings
                  const Text(
                    'Choose Your Path',
                    style: TextStyle(
                      fontSize: 27.0,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0A343D),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2.0),
                  const Text(
                    'Choose one module to start your ANDRIL experience.',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D4B54),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: M2Spacing.md),

                  // Error Banner if present
                  if (_viewModel.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(M2Spacing.md),
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

                  // Module Card Carousel Viewport
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Carousel Arrow
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 20.0,
                          color: Color(0xFF0D9488),
                        ),
                        onPressed: _viewModel.prevCard,
                        tooltip: 'Previous Module',
                      ),

                      // Center Module Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _viewModel.selectModuleIndex(
                            _viewModel.currentIndex,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            height: 360.0,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(28.0),
                              border: Border.all(
                                color: isSelected
                                    ? activeModule.accentColor
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 2.5 : 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? activeModule.accentColor.withValues(alpha: 0.28)
                                      : Colors.black.withValues(alpha: 0.06),
                                  blurRadius: isSelected ? 22.0 : 12.0,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Top Visual Art Container
                                Expanded(
                                  flex: 65,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: activeModule.accentColor
                                          .withValues(alpha: 0.08),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(26.0),
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Themed Vector Illustration
                                        Center(
                                          child: Container(
                                            width: 104.0,
                                            height: 104.0,
                                            decoration: BoxDecoration(
                                              color: activeModule.accentColor
                                                  .withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              activeModule.icon,
                                              size: 56.0,
                                              color: activeModule.accentColor,
                                            ),
                                          ),
                                        ),

                                        // Selected Checkmark Badge
                                        if (isSelected)
                                          Positioned(
                                            top: 12.0,
                                            right: 12.0,
                                            child: Container(
                                              width: 32.0,
                                              height: 32.0,
                                              decoration: BoxDecoration(
                                                color: activeModule.accentColor,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: activeModule
                                                        .accentColor
                                                        .withValues(alpha: 0.4),
                                                    blurRadius: 8.0,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.check_rounded,
                                                size: 20.0,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Bottom Details Container
                                Expanded(
                                  flex: 35,
                                  child: Padding(
                                    padding: const EdgeInsets.all(M2Spacing.md),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 8.0,
                                                  height: 8.0,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        activeModule.accentColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6.0),
                                                Text(
                                                  activeModule.moduleNumber,
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w800,
                                                    color:
                                                        activeModule.accentColor,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (activeModule.isAgeRestricted)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6.0,
                                                  vertical: 1.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFFEF3C7),
                                                  borderRadius:
                                                      BorderRadius.circular(6.0),
                                                  border: Border.all(
                                                    color:
                                                        const Color(0xFFFDE68A),
                                                  ),
                                                ),
                                                child: const Text(
                                                  '18+ ONLY',
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFFB45309),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        Text(
                                          activeModule.title,
                                          style: const TextStyle(
                                            fontSize: 20.0,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          activeModule.tagline,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF64748B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6.0,
                                                  vertical: 2.0,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: activeModule.accentColor
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6.0),
                                                ),
                                                child: Text(
                                                  activeModule.badge,
                                                  style: TextStyle(
                                                    fontSize: 10.0,
                                                    fontWeight: FontWeight.w700,
                                                    color: activeModule
                                                        .accentColor,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4.0),
                                            Text(
                                              isSelected
                                                  ? 'Selected'
                                                  : 'Tap to select',
                                              style: TextStyle(
                                                fontSize: 11.0,
                                                fontWeight: FontWeight.w700,
                                                color: isSelected
                                                    ? activeModule.accentColor
                                                    : const Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Right Carousel Arrow
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 20.0,
                          color: Color(0xFF0D9488),
                        ),
                        onPressed: _viewModel.nextCard,
                        tooltip: 'Next Module',
                      ),
                    ],
                  ),

                  const SizedBox(height: M2Spacing.sm),

                  // Carousel Pagination Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _viewModel.modules.length,
                      (index) {
                        final isDotActive = _viewModel.currentIndex == index;
                        return GestureDetector(
                          onTap: () => _viewModel.goToCard(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            width: isDotActive ? 24.0 : 8.0,
                            height: 8.0,
                            decoration: BoxDecoration(
                              color: isDotActive
                                  ? M2Colors.primaryTeal
                                  : M2Colors.primaryTeal.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: M2Spacing.md),

                  // Info Panel Banner
                  Container(
                    padding: const EdgeInsets.all(M2Spacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(M2Spacing.radiusMd),
                      border: Border.all(
                        color: const Color(0xFFCCFBF1),
                        width: 1.0,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 22.0,
                          color: Color(0xFF0D9488),
                        ),
                        SizedBox(width: M2Spacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose one module to get started.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF134E4A),
                                ),
                              ),
                              SizedBox(height: 1.0),
                              Text(
                                'You can change your module later in Settings.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF285E61),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: M2Spacing.sm),

                  // Selected Module Status Pill
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: M2Spacing.md,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: _viewModel.selectedModule.accentColor
                            .withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(M2Spacing.radiusPill),
                        border: Border.all(
                          color: _viewModel.selectedModule.accentColor
                              .withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8.0,
                            height: 8.0,
                            decoration: BoxDecoration(
                              color: _viewModel.selectedModule.accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6.0),
                          Text.rich(
                            TextSpan(
                              text: 'Selected: ',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: _viewModel.selectedModule.accentColor,
                              ),
                              children: [
                                TextSpan(
                                  text: _viewModel.selectedModule.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: M2Spacing.lg),

                  // Primary "Continue" Button
                  M2PrimaryButton(
                    text: 'Continue',
                    isLoading: _viewModel.isLoading,
                    onPressed: _handleContinue,
                  ),

                  const SizedBox(height: M2Spacing.xxl),
                ],
              ),
            ),

            // Modal 1: 18+ Age & Social Verification Modal
            if (_viewModel.isSocialModalOpen)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(M2Spacing.xl),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32.0),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 44.0,
                            height: 5.0,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: M2Spacing.md),
                        Row(
                          children: [
                            Container(
                              width: 42.0,
                              height: 42.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: const Center(
                                child: Text(
                                  '18+',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF9333EA),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: M2Spacing.sm),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Age & Social Verification',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'ANDRIL Social Module Requirement',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: M2Spacing.md),
                        Container(
                          padding: const EdgeInsets.all(M2Spacing.md),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5FF),
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                          ),
                          child: const Text(
                            'The Social module connects you directly with local communities, events, and peers. To ensure a safe environment, please confirm you are at least 18 years old and agree to our Community Guidelines.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF581C87),
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: M2Spacing.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24.0,
                              height: 24.0,
                              child: Checkbox(
                                value: _viewModel.socialConsentChecked,
                                activeColor: const Color(0xFF9333EA),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                onChanged: (val) =>
                                    _viewModel.setSocialConsentChecked(val ?? false),
                              ),
                            ),
                            const SizedBox(width: M2Spacing.sm),
                            const Expanded(
                              child: Text(
                                'I confirm that I am 18 years of age or older and agree to the ANDRIL Social safety guidelines.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: M2Spacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _viewModel.closeSocialModal,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.0),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: M2Spacing.sm),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _viewModel.confirmSocialSelection,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9333EA),
                                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.0),
                                  ),
                                ),
                                child: const Text(
                                  'Confirm & Select',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
