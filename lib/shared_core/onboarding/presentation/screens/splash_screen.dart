import 'package:flutter/material.dart';
import '../../../../app/themes/shared_core/components/m2_background_scaffold.dart';
import '../../../../app/themes/shared_core/spacing/m2_spacing.dart';
import '../viewmodels/splash_viewmodel.dart';
import '../widgets/animated_dots_indicator.dart';
import '../widgets/brand_logo_header.dart';

/// Screen 01: ANDRIL Splash Screen.
///
/// Implements the finalized `01-Splash_Screen_modified.png` design:
/// - Signature soft mint-cyan background gradient and ambient curves.
/// - Centered brand emblem, wordmark, and tagline ("Every Path Begins Here").
/// - Bottom animated three-dot indicator.
/// - Auto-completion callback for transitioning to language selection.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.onSplashComplete,
    this.duration = const Duration(milliseconds: 2400),
    this.viewModel,
  });

  final VoidCallback? onSplashComplete;
  final Duration duration;
  final SplashViewModel? viewModel;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final SplashViewModel _viewModel;
  bool _ownsViewModel = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _viewModel = SplashViewModel(splashDuration: widget.duration);
      _ownsViewModel = true;
    }

    _viewModel.startSplashTimer(onComplete: () {
      if (mounted) {
        widget.onSplashComplete?.call();
      }
    });
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return const Column(
            children: [
              const Spacer(flex: 3),

              // Centered Brand Logo & Tagline
              const Center(
                child: BrandLogoHeader(
                  emblemSize: 140.0,
                  spacing: M2Spacing.md,
                ),
              ),

              const Spacer(flex: 3),

              // Bottom Pulsing Dots Indicator
              const Padding(
                padding: EdgeInsets.only(bottom: M2Spacing.hero),
                child: Center(
                  child: AnimatedDotsIndicator(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
