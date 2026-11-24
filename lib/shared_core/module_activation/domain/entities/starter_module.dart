import 'package:flutter/material.dart';

/// Module data definition for Screen 10 (Starter Module Selection).
class StarterModule {
  const StarterModule({
    required this.id,
    required this.moduleNumber,
    required this.title,
    required this.tagline,
    required this.badge,
    required this.accentColor,
    required this.icon,
    this.isAgeRestricted = false,
    this.minAge = 0,
    this.assetImagePath,
  });

  final String id;
  final String moduleNumber;
  final String title;
  final String tagline;
  final String badge;
  final Color accentColor;
  final IconData icon;
  final bool isAgeRestricted;
  final int minAge;
  final String? assetImagePath;

  static const List<StarterModule> defaults = [
    StarterModule(
      id: 'learning',
      moduleNumber: 'MODULE 01',
      title: 'Learning',
      tagline: 'Learn, teach and grow together.',
      badge: 'Skill Paths & Mentorship',
      accentColor: Color(0xFF2563EB), // Electric Blue
      icon: Icons.school_rounded,
      assetImagePath:
          'assets/images/shared_core/onboarding/10 Choose_Modules_No_Logo_1440x3120/learning.png',
    ),
    StarterModule(
      id: 'hobbies',
      moduleNumber: 'MODULE 02',
      title: 'Hobbies',
      tagline: 'Explore your passions and creative interests.',
      badge: 'Creative & Sports',
      accentColor: Color(0xFF059669), // Fresh Emerald Green
      icon: Icons.palette_rounded,
      assetImagePath:
          'assets/images/shared_core/onboarding/10 Choose_Modules_No_Logo_1440x3120/hobbies.png',
    ),
    StarterModule(
      id: 'social',
      moduleNumber: 'MODULE 03',
      title: 'Social',
      tagline: 'Meet and build meaningful connections.',
      badge: 'Community & Events',
      accentColor: Color(0xFF9333EA), // Purple
      icon: Icons.people_alt_rounded,
      isAgeRestricted: true,
      minAge: 18,
      assetImagePath:
          'assets/images/shared_core/onboarding/10 Choose_Modules_No_Logo_1440x3120/social.png',
    ),
  ];
}
