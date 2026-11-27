import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/dependencies/registrations/learning/learning_dependencies.dart';
import '../../../../app/router/learning_router.dart';
import '../../profile/domain/entities/learning_profile.dart';
import '../../profile/domain/repositories/profile_repository.dart';
import '../widgets/learning_home_action_grid.dart';
import 'learning_home_screen.dart';

/// Container widget orchestrating data loading, navigation shortcuts,
/// fail-closed M2 admission evaluation, and session boundary clearing
/// for [LearningHomeScreen].
///
/// Architecture & Security Constraints (BRD §04.3, §05 CF-01, CF-02, CF-03, §06 LRN-01..LRN-06):
/// - Evaluates [LearningAccessPolicy] before requesting or rendering private learner data.
/// - When admission or authentication is lacking, renders fail-closed access-denied state.
/// - Loads authoritative profile and setup data via [LearningDependenciesScope].
/// - Strictly avoids fabricating profile IDs from account IDs or forging XP / streaks.
/// - Keeps unavailable dashboard metrics safely disconnected with explicit explanations.
/// - Enforces session boundary protection: clears private in-memory state on session revocation.
/// - Connects navigation shortcuts to approved Batch 05 screens via GoRouter.
class LearningHomeContainer extends StatefulWidget {
  final LearningDependenciesScope? dependencies;
  final ProfileRepository? profileRepository;
  final LearningAccessPolicy? accessPolicy;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onResume;

  const LearningHomeContainer({
    super.key,
    this.dependencies,
    this.profileRepository,
    this.accessPolicy,
    this.onNotificationTap,
    this.onResume,
  });

  @override
  State<LearningHomeContainer> createState() => _LearningHomeContainerState();
}

class _LearningHomeContainerState extends State<LearningHomeContainer> {
  bool _isLoading = false;
  bool _isAccessDenied = false;
  String? _errorMessage;
  LearningProfile? _profile;
  VoidCallback? _unregisterSessionClearer;

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoad();
    _registerSessionClearer();
  }

  @override
  void didUpdateWidget(covariant LearningHomeContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dependencies != oldWidget.dependencies) {
      _registerSessionClearer();
    }
    if (widget.accessPolicy != oldWidget.accessPolicy ||
        widget.dependencies != oldWidget.dependencies ||
        widget.profileRepository != oldWidget.profileRepository) {
      _checkAccessAndLoad();
    }
  }

  void _registerSessionClearer() {
    _unregisterSessionClearer?.call();
    _unregisterSessionClearer = widget.dependencies?.sessionController
        ?.registerPrivateStateClearer(_clearPrivateState);
  }

  void _clearPrivateState() {
    if (mounted) {
      setState(() {
        _profile = null;
        _errorMessage = null;
        _isAccessDenied = true;
      });
    }
  }

  @override
  void dispose() {
    _unregisterSessionClearer?.call();
    _unregisterSessionClearer = null;
    super.dispose();
  }

  Future<void> _checkAccessAndLoad() async {
    final policy = widget.accessPolicy;
    if (policy != null &&
        (!policy.isAuthenticated || !policy.isLearningActivated)) {
      if (mounted) {
        setState(() {
          _isAccessDenied = true;
          _isLoading = false;
          _profile = null;
        });
      }
      return;
    }

    final repo =
        widget.profileRepository ?? widget.dependencies?.profileRepository;
    if (repo == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAccessDenied = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isAccessDenied = false;
    });

    try {
      final result = await repo.getProfile();
      if (!mounted) return;

      switch (result) {
        case ProfileSuccess(:final data):
          setState(() {
            _profile = data;
            _isLoading = false;
            _errorMessage = null;
          });
        case ProfileAccessDenied():
          setState(() {
            _profile = null;
            _isAccessDenied = true;
            _isLoading = false;
          });
        case ProfileDependencyUnavailable(:final message):
          setState(() {
            _errorMessage = message;
            _isLoading = false;
          });
        case ProfileNotFound():
          setState(() {
            _profile = null;
            _isLoading = false;
          });
        case ProfileFailure(:final message):
          setState(() {
            _errorMessage = message;
            _isLoading = false;
          });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load learning home data';
        _isLoading = false;
      });
    }
  }

  List<LearningHomeActionItem> _buildActionItems(BuildContext context) {
    return [
      LearningHomeActionItem(
        id: 'action_learning_circles',
        title: 'Learning Circles',
        icon: Icons.groups_rounded,
        onTap: () => context.go('/learning/circles'),
      ),
      LearningHomeActionItem(
        id: 'action_study_pacts',
        title: 'Study Pacts',
        icon: Icons.handshake_rounded,
        onTap: () => context.go('/learning/pacts'),
      ),
      LearningHomeActionItem(
        id: 'action_growth_dashboard',
        title: 'Growth Dashboard',
        icon: Icons.trending_up_rounded,
        onTap: () => context.go('/learning/growth'),
      ),
      LearningHomeActionItem(
        id: 'action_mentorship',
        title: 'Mentorship',
        icon: Icons.psychology_rounded,
        onTap: () => context.go('/learning/growth/mentorship'),
      ),
      LearningHomeActionItem(
        id: 'action_cv_maker',
        title: 'CV Maker',
        icon: Icons.description_rounded,
        onTap: () => context.go('/learning/cv-maker'),
      ),
      LearningHomeActionItem(
        id: 'action_portfolio_maker',
        title: 'Portfolio Maker',
        icon: Icons.folder_special_rounded,
        onTap: () => context.go('/learning/portfolio-maker'),
      ),
      LearningHomeActionItem(
        id: 'action_partner_discovery',
        title: 'Partner Discovery',
        icon: Icons.person_search_rounded,
        onTap: () => context.go('/learning/discovery'),
      ),
      LearningHomeActionItem(
        id: 'action_connections',
        title: 'Connections',
        icon: Icons.people_outline_rounded,
        onTap: () => context.go('/learning/connections'),
      ),
      LearningHomeActionItem(
        id: 'action_skill_exchange',
        title: 'Skill Exchange',
        icon: Icons.swap_horiz_rounded,
        onTap: () => context.go('/learning/skill-exchange'),
      ),
      LearningHomeActionItem(
        id: 'action_classrooms',
        title: 'Classrooms Hub',
        icon: Icons.school_rounded,
        onTap: () => context.go('/learning/classrooms/hub'),
      ),
      LearningHomeActionItem(
        id: 'action_profile_editor',
        title: 'Edit Profile',
        icon: Icons.manage_accounts_rounded,
        onTap: () => context.go('/learning/profile/editor'),
      ),
      const LearningHomeActionItem(
        id: 'action_ai_study_planner',
        title: 'AI Study Planner',
        icon: Icons.auto_awesome_rounded,
        unavailableReason: 'AI planning engine pending backend deployment',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final displayName = profile?.displayName.trim() ?? '';
    final effectiveDisplayName =
        displayName.isNotEmpty ? displayName : 'Learner';

    ImageProvider<Object>? avatarImage;
    final avatarUrl = profile?.avatarUrl?.trim();
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatarImage = NetworkImage(avatarUrl);
    }

    final goalTitle = (profile != null && profile.learningGoals.isNotEmpty)
        ? profile.learningGoals.first
        : null;

    final weeklyCommitmentText = profile?.preferences.availability;

    return LearningHomeScreen(
      displayName: effectiveDisplayName,
      statusText: 'Learning Home',
      avatarImage: avatarImage,
      goalTitle: goalTitle,
      completionPercent:
          null, // No fake XP or unverified completion calculations
      weeklyCommitmentText: weeklyCommitmentText,
      actions: _buildActionItems(context),
      actionsTitle: 'My Learning Hub',
      onNotificationTap: widget.onNotificationTap ??
          () {
            context.go('/learning/chat');
          },
      onResume: widget.onResume ??
          () {
            context.go('/learning/pacts');
          },
      isLoading: _isLoading,
      isAccessDenied: _isAccessDenied,
      errorMessage: _errorMessage,
      onRetry: _checkAccessAndLoad,
    );
  }
}
