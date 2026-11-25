import 'package:flutter/material.dart';
import 'package:andril_mobile/app/themes/social/social_theme.dart';
import '../viewmodels/social_home_viewmodel.dart';

/// 2x2 Quick Action Grid for Social Home (S21).
///
/// Renders four action cards:
/// 1. My Connections (Matches & pending interest)
/// 2. Andril Diary (Your private reflections)
/// 3. Personality (Optional style insights)
/// 4. Saved Profiles (Revisit bookmarks)
class SocialHomeActionGrid extends StatelessWidget {
  final List<SocialHomeQuickAction> actions;
  final ValueChanged<SocialHomeActionId>? onActionTap;

  const SocialHomeActionGrid({
    super.key,
    this.actions = SocialHomeViewModel.defaultQuickActions,
    this.onActionTap,
  });

  IconData _iconForAction(SocialHomeActionId id) {
    switch (id) {
      case SocialHomeActionId.myConnections:
        return Icons.people_outline_rounded;
      case SocialHomeActionId.andrilDiary:
        return Icons.auto_stories_outlined;
      case SocialHomeActionId.personality:
        return Icons.psychology_outlined;
      case SocialHomeActionId.savedProfiles:
        return Icons.bookmark_border_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AndrilSocialColors.ink,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: actions.map((action) {
                  return SizedBox(
                    width: cardWidth,
                    child: _ActionCard(
                      action: action,
                      icon: _iconForAction(action.id),
                      onTap: () => onActionTap?.call(action.id),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final SocialHomeQuickAction action;
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.action,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AndrilSocialColors.border,
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AndrilSocialColors.faintPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: AndrilSocialColors.royalPurple,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AndrilSocialColors.copper,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                action.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AndrilSocialColors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                action.subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: AndrilSocialColors.ink.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal carousel section displaying recommended people on Social Home (S21).
class SocialRecommendedPeopleSection extends StatelessWidget {
  final List<SocialRecommendedPerson> people;
  final ValueChanged<String>? onViewProfile;
  final VoidCallback? onSeeAll;

  const SocialRecommendedPeopleSection({
    super.key,
    required this.people,
    this.onViewProfile,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recommended for you',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AndrilSocialColors.ink,
                  ),
                ),
                if (onSeeAll != null)
                  TextButton(
                    onPressed: onSeeAll,
                    style: TextButton.styleFrom(
                      foregroundColor: AndrilSocialColors.royalPurple,
                      minimumSize: const Size(60, 48),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See all',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              scrollDirection: Axis.horizontal,
              itemCount: people.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final person = people[index];
                return _RecommendedPersonCard(
                  person: person,
                  onTap: () => onViewProfile?.call(person.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedPersonCard extends StatelessWidget {
  final SocialRecommendedPerson person;
  final VoidCallback? onTap;

  const _RecommendedPersonCard({
    required this.person,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AndrilSocialColors.border,
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AndrilSocialColors.faintPurple,
            backgroundImage: (person.photoUrl != null && person.photoUrl!.isNotEmpty)
                ? NetworkImage(person.photoUrl!)
                : null,
            child: (person.photoUrl == null || person.photoUrl!.isEmpty)
                ? Text(
                    person.displayName.isNotEmpty
                        ? person.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AndrilSocialColors.royalPurple,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            person.displayName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AndrilSocialColors.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            person.location,
            style: TextStyle(
              fontSize: 11,
              color: AndrilSocialColors.ink.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: AndrilSocialColors.royalPurple,
                  width: 1.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'View',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AndrilSocialColors.royalPurple,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
