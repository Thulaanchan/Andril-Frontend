import 'package:flutter/material.dart';

import '../../../../app/themes/social/social_theme.dart';
import '../domain/social_relationship.dart';

/// Immutable record of a past or current connection.
class SocialMatchHistoryRecord {
  final String id;
  final String displayName;
  final String? photoUrl;
  final DateTime matchedAt;
  final DateTime? endedAt;
  final SocialRelationshipType status;

  const SocialMatchHistoryRecord({
    required this.id,
    required this.displayName,
    this.photoUrl,
    required this.matchedAt,
    this.endedAt,
    required this.status,
  });
}

/// Screens S86 (Match History) and S88 (No Connections Yet).
///
/// Follows M5 requirements:
/// - Displays authorized chronological connection history.
/// - Clearly differentiates active matches from revoked/unmatched records.
/// - S88: Clean empty state with Explore action.
/// - Strictly fails closed: No fabricated history, no unauthorized chat access for ended matches.
class SocialMatchHistoryScreen extends StatelessWidget {
  final List<SocialMatchHistoryRecord> historyRecords;
  final VoidCallback? onBack;
  final VoidCallback? onExplore;
  final bool isAuthorized;

  const SocialMatchHistoryScreen({
    super.key,
    required this.historyRecords,
    this.onBack,
    this.onExplore,
    this.isAuthorized = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AndrilSocialColors.cream,
      appBar: AppBar(
        backgroundColor: AndrilSocialColors.cream,
        foregroundColor: AndrilSocialColors.ink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back',
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Match History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AndrilSocialColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!isAuthorized) {
      return _buildAccessDeniedState();
    }

    if (historyRecords.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: historyRecords.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final record = historyRecords[index];
        final isActive = record.status == SocialRelationshipType.connected;

        return Card(
          elevation: 0,
          color: AndrilSocialColors.canvasCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AndrilSocialColors.border, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFEDE8F4),
                  backgroundImage: record.photoUrl != null ? NetworkImage(record.photoUrl!) : null,
                  child: record.photoUrl == null
                      ? Text(
                          record.displayName.isNotEmpty ? record.displayName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AndrilSocialColors.royalPurple,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AndrilSocialColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Matched: ${_formatDate(record.matchedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      if (record.endedAt != null)
                        Text(
                          'Ended: ${_formatDate(record.endedAt!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                    ],
                  ),
                ),

                // Status Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AndrilSocialColors.royalPurple.withValues(alpha: 0.1)
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Connected' : 'Unmatched',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AndrilSocialColors.royalPurple : const Color(0xFF616161),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE8F4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 40,
                color: AndrilSocialColors.royalPurple,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Connections Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AndrilSocialColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When you and another member mutually like each other, you\'ll see your connection history here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
            if (onExplore != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onExplore,
                icon: const Icon(Icons.explore_outlined, size: 20),
                label: const Text('Discover People'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AndrilSocialColors.royalPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDeniedState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: Color(0xFFE63946)),
            SizedBox(height: 16),
            Text(
              'Access Restricted',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AndrilSocialColors.ink),
            ),
            SizedBox(height: 8),
            Text(
              'Match history requires an active authorized Social session.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
