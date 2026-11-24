import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/colors/m2_colors.dart';
import '../../../../app/themes/shared_core/components/m2_background_scaffold.dart';
import '../../../../app/themes/shared_core/components/m2_buttons.dart';
import '../../../../app/themes/shared_core/spacing/m2_spacing.dart';
import '../../../../app/themes/shared_core/typography/m2_typography.dart';
import '../../onboarding/presentation/widgets/language_card.dart';
import '../data/repositories/shared_prefs_language_preference_repository.dart';
import '../viewmodels/language_selection_viewmodel.dart';

/// Screen 02: ANDRIL Choose Your Language Screen.
///
/// Implements the finalized `02 Choose Your Language App Screen.png` design:
/// - Screen title & subtitle ("Select your preferred language for Andril.")
/// - Three language options: English, Tamil, Sinhala with custom gradient badges.
/// - Interactive radio selection and cyan/teal glow border.
/// - Informational callout: "You can change your language later in Settings."
/// - Primary action "Continue" button with trailing arrow in circle.
/// - Local persistence of selection via [LanguageSelectionViewModel].
class ChooseLanguageScreen extends StatefulWidget {
  const ChooseLanguageScreen({
    super.key,
    this.onContinue,
    this.viewModel,
  });

  final VoidCallback? onContinue;
  final LanguageSelectionViewModel? viewModel;

  @override
  State<ChooseLanguageScreen> createState() => _ChooseLanguageScreenState();
}

class _ChooseLanguageScreenState extends State<ChooseLanguageScreen> {
  late final LanguageSelectionViewModel _viewModel;
  bool _ownsViewModel = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _viewModel = LanguageSelectionViewModel(
        repository: SharedPrefsLanguagePreferenceRepository(),
      );
      _ownsViewModel = true;
    }

    _viewModel.loadSavedLanguage();
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return M2BackgroundScaffold(
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: M2Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: M2Spacing.md),

                // Top Centered Screen Header Label
                Center(
                  child: Text(
                    'Choose Your Language',
                    style: M2Typography.heroTitle.copyWith(
                      fontSize: 17.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: M2Spacing.xxl),

                // Main Hero Titles
                const Text(
                  'Choose Your Language',
                  style: M2Typography.heroTitle,
                ),
                const SizedBox(height: M2Spacing.xs),
                const Text(
                  'Select your preferred language for Andril.',
                  style: M2Typography.heroSubtitle,
                ),

                const SizedBox(height: M2Spacing.xl),

                // Language Option Cards
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _viewModel.availableLanguages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: M2Spacing.md),
                    itemBuilder: (context, index) {
                      final language = _viewModel.availableLanguages[index];
                      final isSelected = _viewModel.selectedLanguage == language;

                      return LanguageCard(
                        language: language,
                        isSelected: isSelected,
                        onTap: () => _viewModel.selectLanguage(language),
                      );
                    },
                  ),
                ),

                // Information Callout Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: M2Spacing.md,
                    vertical: M2Spacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: M2Colors.primaryTealSurface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(M2Spacing.radiusMd),
                    border: Border.all(
                      color: M2Colors.primaryTealBorder.withValues(alpha: 0.6),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28.0,
                        height: 28.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: M2Colors.primaryTealLight,
                            width: 2.0,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'i',
                            style: TextStyle(
                              color: M2Colors.primaryTealLight,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'serif',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: M2Spacing.sm),
                      const Expanded(
                        child: Text(
                          'You can change your language later in Settings.',
                          style: M2Typography.infoText,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: M2Spacing.xl),

                // Bottom Action Button
                M2PrimaryButton(
                  text: 'Continue',
                  isLoading: _viewModel.isSaving,
                  onPressed: () {
                    _viewModel.saveAndContinue(onSuccess: widget.onContinue);
                  },
                ),

                const SizedBox(height: M2Spacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}
