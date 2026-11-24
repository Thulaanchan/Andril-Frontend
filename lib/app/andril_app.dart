import 'package:flutter/material.dart';
import '../shared_core/onboarding/presentation/screens/onboarding_flow_coordinator.dart';
import 'bootstrap/scaffold_home.dart';

/// ANDRIL Mobile application root widget.
///
/// Connects Feature 01 [OnboardingFlowCoordinator] as the primary user onboarding flow,
/// while preserving [ScaffoldHome] for technical starter shell verification.
class AndrilApp extends StatelessWidget {
  const AndrilApp({
    super.key,
    this.home = const OnboardingFlowCoordinator(),
  });

  /// Starter shell constructor preserving access to [ScaffoldHome] for technical scaffolding verification.
  const AndrilApp.starterShell({
    super.key,
    this.home = const ScaffoldHome(),
  });

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ANDRIL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF364B66)),
        useMaterial3: true,
      ),
      home: home,
    );
  }
}
