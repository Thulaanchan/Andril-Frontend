import 'package:flutter/material.dart';
import '../../../../app/themes/social/social_prototype_theme.dart';
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
        return Icons.menu_book_outlined;
      case SocialHomeActionId.personality:
        return Icons.psychology_outlined;
      case SocialHomeActionId.savedProfiles:
        return Icons.bookmark_border_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Explore your Social world',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: SocialPrototypeColors.textPrimary,
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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 126),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x082D1155), blurRadius: 8, offset: Offset(0, 2))
            ],
            border: Border.all(
              color: SocialPrototypeColors.borderLight,
              width: 1.0,
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4ECFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: SocialPrototypeColors.primaryPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                action.title,
                style: const TextStyle(
                  fontSize: 15,
                  letterSpacing: -0.2,
                  fontWeight: FontWeight.w700,
                  color: SocialPrototypeColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                switch (action.id) {
                  SocialHomeActionId.myConnections => 'View your matches',
                  SocialHomeActionId.andrilDiary => 'Reflect & grow',
                  SocialHomeActionId.personality => 'Review quiz',
                  SocialHomeActionId.savedProfiles => 'Profiles you kept',
                },
                style: const TextStyle(
                  fontSize: 12,
                  color: SocialPrototypeColors.textMuted,
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
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'Recommended people',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: SocialPrototypeColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onSeeAll != null)
                  TextButton(
                    onPressed: onSeeAll,
                    style: TextButton.styleFrom(
                      foregroundColor: SocialPrototypeColors.primaryPurple,
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
            height: 220,
            child: people.isEmpty
                ? const Center(
                    child: Text('No recommendations currently available.',
                        style: TextStyle(
                            fontSize: 13,
                            color: SocialPrototypeColors.textMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
      width: 140,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SocialPrototypeColors.borderLight,
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                  width: 72,
                  height: 72,
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: SocialPrototypeColors.lavenderTint,
                    backgroundImage:
                        (person.photoUrl != null && person.photoUrl!.isNotEmpty)
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
                              color: SocialPrototypeColors.primaryPurple,
                            ),
                          )
                        : null,
                  ))),
          const SizedBox(height: 10),
          Text(
            person.displayName,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: SocialPrototypeColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            person.location,
            style: const TextStyle(
              fontSize: 12,
              color: SocialPrototypeColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: SocialPrototypeColors.primaryPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                side: const BorderSide(
                  color: SocialPrototypeColors.primaryPurple,
                  width: 1.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'View profile',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
