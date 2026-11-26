import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import '../../domain/entities/learning_growth_evidence.dart';
import '../../domain/entities/learning_mentorship.dart';
import '../viewmodels/learning_mentorship_viewmodel.dart';
import 'mentorship_agreement_screen.dart';
import 'request_mentorship_screen.dart';

/// Hub screen managing voluntary learning mentorship discovery, requests, and active agreements (LRN-04, GRW-01-05).
///
/// Features:
/// 1. Tabbed navigation: Discover Mentors, Requests, and Active Agreements with numerical badges.
/// 2. Disconnected backend notice banner when operating in local presentation mode.
/// 3. Initiating mentorship requests to available volunteer mentors.
/// 4. Reviewing mutual agreement timeline and status.
/// 5. Responsive layout across 320dp, 360dp, 412dp viewports and with 1.5x dynamic font scale.
class LearningMentorshipHubScreen extends StatefulWidget {
  final LearningMentorshipViewModel viewModel;
  final PreferredSizeWidget? appBar;

  const LearningMentorshipHubScreen({
    super.key,
    required this.viewModel,
    this.appBar,
  });

  @override
  State<LearningMentorshipHubScreen> createState() =>
      _LearningMentorshipHubScreenState();
}

class _LearningMentorshipHubScreenState
    extends State<LearningMentorshipHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);

    widget.viewModel.addListener(_onViewModelChanged);

    if (widget.viewModel.status == MentorshipViewStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.viewModel.initialize();
      });
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0:
        widget.viewModel.switchTab(MentorshipTab.discover);
        break;
      case 1:
        widget.viewModel.switchTab(MentorshipTab.requests);
        break;
      case 2:
        widget.viewModel.switchTab(MentorshipTab.active);
        break;
    }
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _openRequestScreen(LearningMentorshipOffer offer) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RequestMentorshipScreen(
          viewModel: widget.viewModel,
          offer: offer,
        ),
      ),
    );
  }

  void _openAgreementScreen(String mentorshipId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MentorshipAgreementScreen(
          viewModel: widget.viewModel,
          mentorshipId: mentorshipId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.background,
      appBar: widget.appBar ?? _buildDefaultAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildDisconnectedBanner(),
            _buildTabBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildDefaultAppBar() {
    return AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Learning Mentorship',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: LearningColors.heading,
            ),
          ),
          Text(
            'Voluntary peer guidance & mutually agreed goals',
            style: TextStyle(
              fontSize: 11,
              color: LearningColors.secondaryText,
            ),
          ),
        ],
      ),
      backgroundColor: LearningColors.cardSurface,
      elevation: 0,
      iconTheme: const IconThemeData(color: LearningColors.heading),
    );
  }

  Widget _buildDisconnectedBanner() {
    return Container(
      key: const ValueKey('banner_mentorship_disconnected'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: const Color(0xFFFEF3C7),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Color(0xFFB45309)),
          SizedBox(width: 8.0),
          Expanded(
            child: Text(
              LearningGrowthEvidence.disconnectedNotice,
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: LearningColors.primary,
        unselectedLabelColor: LearningColors.secondaryText,
        indicatorColor: LearningColors.primary,
        indicatorWeight: 3.0,
        tabs: [
          Tab(
            key: const ValueKey('tab_mentors_discover'),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Discover Mentors'),
                  if (widget.viewModel.availableOffersCount > 0) ...[
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '${widget.viewModel.availableOffersCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: LearningColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Tab(
            key: const ValueKey('tab_mentors_requests'),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Requests'),
                  if (widget.viewModel.pendingRequestsCount > 0) ...[
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '${widget.viewModel.pendingRequestsCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Tab(
            key: const ValueKey('tab_mentors_active'),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Active Agreements'),
                  if (widget.viewModel.activeAgreementsCount > 0) ...[
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '${widget.viewModel.activeAgreementsCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (widget.viewModel.status) {
      case MentorshipViewStatus.initial:
      case MentorshipViewStatus.loading:
        return const Center(
          child: CircularProgressIndicator(
            key: ValueKey('loading_indicator'),
          ),
        );

      case MentorshipViewStatus.accessDenied:
        return _buildAccessDeniedState();

      case MentorshipViewStatus.unavailableService:
        return _buildUnavailableState();

      case MentorshipViewStatus.error:
        return _buildErrorState();

      case MentorshipViewStatus.empty:
      case MentorshipViewStatus.ready:
        return TabBarView(
          controller: _tabController,
          children: [
            _buildDiscoverTab(),
            _buildRequestsTab(),
            _buildActiveTab(),
          ],
        );
    }
  }

  Widget _buildAccessDeniedState() {
    return Center(
      key: const ValueKey('state_access_denied'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline,
                  size: 48, color: Colors.red.shade700),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Access Restricted',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.viewModel.errorMessage ??
                  'Authentication and an activated Learning profile are required.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableState() {
    return Center(
      key: const ValueKey('state_unavailable'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_outlined,
                  size: 48, color: Colors.amber.shade700),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Mentorship Service Unavailable',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.viewModel.errorMessage ??
                  LearningGrowthEvidence.disconnectedNotice,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              key: const ValueKey('btn_retry_unavailable'),
              onPressed: () => widget.viewModel.initialize(force: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 44),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      key: const ValueKey('state_error'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  size: 48, color: Colors.red.shade700),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Unable to Load Mentorship',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.viewModel.errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: LearningColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              key: const ValueKey('btn_retry_error'),
              onPressed: () => widget.viewModel.initialize(force: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 44),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    final offers = widget.viewModel.offers;

    if (offers.isEmpty) {
      return const Center(
        key: ValueKey('view_offers_empty'),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline,
                  size: 48, color: LearningColors.secondaryText),
              SizedBox(height: 16.0),
              Text(
                'No Volunteer Mentors Available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'Mentorship is entirely voluntary. Check back later as mentors declare availability.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: LearningColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      key: const ValueKey('view_tab_discover'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        final mentor = offer.mentor;

        return Card(
          key: ValueKey('card_offer_${offer.id}'),
          margin: const EdgeInsets.only(bottom: 12.0),
          color: Colors.white,
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFEEF2FF),
                      child: Text(
                        mentor.displayName.isNotEmpty
                            ? mentor.displayName[0]
                            : 'M',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: LearningColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mentor.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: LearningColors.heading,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: const Text(
                              'Volunteer Mentor',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (offer.specialtyTopics.isNotEmpty) ...[
                  const SizedBox(height: 12.0),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: offer.specialtyTopics.map((topic) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          topic,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 14.0),
                SizedBox(
                  width: double.infinity,
                  height: 44.0,
                  child: ElevatedButton(
                    key: ValueKey('btn_open_request_${offer.id}'),
                    onPressed: () => _openRequestScreen(offer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LearningColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('Request Mentorship'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    final pending = widget.viewModel.pendingRequests;

    if (pending.isEmpty) {
      return const Center(
        key: ValueKey('view_requests_empty'),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mail_outline,
                  size: 48, color: LearningColors.secondaryText),
              SizedBox(height: 16.0),
              Text(
                'No Pending Requests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'You have no pending mentorship requests.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: LearningColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      key: const ValueKey('view_tab_requests'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final item = pending[index];
        return Card(
          key: ValueKey('card_request_${item.id}'),
          margin: const EdgeInsets.only(bottom: 12.0),
          color: Colors.white,
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            onTap: () => _openAgreementScreen(item.id),
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.mentor.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: LearningColors.heading,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time,
                                size: 12, color: Color(0xFFB45309)),
                            SizedBox(width: 4.0),
                            Text(
                              'Awaiting Response',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    item.learningGoal,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: LearningColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'View Status →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: LearningColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveTab() {
    final active = widget.viewModel.activeAgreements;

    if (active.isEmpty) {
      return const Center(
        key: ValueKey('view_active_empty'),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.handshake_outlined,
                  size: 48, color: LearningColors.secondaryText),
              SizedBox(height: 16.0),
              Text(
                'No Active Agreements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'Active mentorship starts when a mentor accepts your voluntary request.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: LearningColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      key: const ValueKey('view_tab_active'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: active.length,
      itemBuilder: (context, index) {
        final item = active[index];
        return Card(
          key: ValueKey('card_active_${item.id}'),
          margin: const EdgeInsets.only(bottom: 12.0),
          color: Colors.white,
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            onTap: () => _openAgreementScreen(item.id),
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.mentor.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: LearningColors.heading,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 12, color: Color(0xFF15803D)),
                            SizedBox(width: 4.0),
                            Text(
                              'Mentorship agreed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    item.learningGoal,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'View Agreement →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: LearningColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
