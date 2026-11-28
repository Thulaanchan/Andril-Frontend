import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import 'package:andril_mobile/features/shared/presentation/widgets/error_retry_card.dart';
import '../../domain/entities/skill_exchange.dart';
import '../../domain/entities/skill_exchange_participant.dart';
import '../../domain/entities/skill_partner.dart';
import '../widgets/propose_exchange_dialog.dart';
import '../widgets/skill_exchange_card.dart';
import '../widgets/skill_filter_bar.dart';
import '../widgets/skill_partner_card.dart';

/// Presentation screen for the Learning Skill Exchange Hub (LRN-01, BRD §06 p. 9).
///
/// Features:
/// - Offer a Skill and Learn a Skill actions and filters.
/// - Skill search and approved category filtering.
/// - Eligible Learning partner presentation with offered and wanted skills.
/// - Exchange request and mutual agreement states.
/// - My Skill Exchanges summary with verified local data.
/// - Loading, empty, unavailable, access-denied, error, and confirmation states.
/// - Session revocation: switches in [currentUserId] instantly purge dirty state.
/// - Fail-closed security: unauthenticated or unactivated callers cannot access exchange.
class SkillExchangeHubScreen extends StatefulWidget {
  final String currentUserId;
  final String currentAccountId;
  final String currentDisplayName;
  final List<String> userSkillsToShare;
  final List<String> userSkillsToLearn;
  final bool isLearningActivated;
  final bool isLoading;
  final String? errorMessage;
  final bool isUnavailable;
  final List<SkillPartner>? initialPartners;
  final List<SkillExchange>? initialExchanges;
  final VoidCallback? onBack;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenPacts;

  const SkillExchangeHubScreen({
    super.key,
    required this.currentUserId,
    this.currentAccountId = 'acc_current_user',
    this.currentDisplayName = 'Thusa Learner',
    this.userSkillsToShare = const [
      'Flutter',
      'Dart',
      'Clean Architecture',
    ],
    this.userSkillsToLearn = const [
      'Figma',
      'UI/UX Design',
    ],
    this.isLearningActivated = true,
    this.isLoading = false,
    this.errorMessage,
    this.isUnavailable = false,
    this.initialPartners,
    this.initialExchanges,
    this.onBack,
    this.onRetry,
    this.onOpenPacts,
  });

  @override
  State<SkillExchangeHubScreen> createState() => _SkillExchangeHubScreenState();
}

class _SkillExchangeHubScreenState extends State<SkillExchangeHubScreen> {
  static const Color _errorColor = Color(0xFFDC2626);

  int _selectedTabIndex = 0; // 0 = Discover Partners, 1 = My Exchanges
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _filterOfferOnly = false;
  bool _filterLearnOnly = false;

  late List<SkillPartner> _partners;
  late List<SkillExchange> _myExchanges;
  String? _confirmationBannerMessage;
  BuildContext? _proposalDialogContext;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    if (!widget.isLearningActivated ||
        widget.isUnavailable ||
        widget.currentUserId.trim().isEmpty ||
        widget.currentAccountId.trim().isEmpty) {
      _partners = [];
      _myExchanges = [];
      return;
    }
    _partners = List.of(widget.initialPartners ?? SkillPartner.samplePartners);
    _myExchanges = (widget.initialExchanges ?? <SkillExchange>[])
        .where((e) =>
            e.sender == _currentParticipant ||
            e.recipient == _currentParticipant)
        .toList();
  }

  @override
  void didUpdateWidget(SkillExchangeHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Session revocation: Purge state immediately when caller ID changes.
    if (widget.currentUserId != oldWidget.currentUserId ||
        widget.currentAccountId != oldWidget.currentAccountId ||
        widget.isLearningActivated != oldWidget.isLearningActivated ||
        widget.isUnavailable != oldWidget.isUnavailable) {
      _searchController.clear();
      _selectedCategory = 'All';
      _filterOfferOnly = false;
      _filterLearnOnly = false;
      _confirmationBannerMessage = null;
      _selectedTabIndex = 0;
      _initData();
      final dialogContext = _proposalDialogContext;
      if (dialogContext != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!dialogContext.mounted) return;
          final route = ModalRoute.of(dialogContext);
          if (route != null) Navigator.of(dialogContext).removeRoute(route);
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  SkillExchangeParticipant get _currentParticipant => SkillExchangeParticipant(
        accountId: widget.currentAccountId,
        learningProfileId: widget.currentUserId,
      );

  void _handleProposeExchange(SkillPartner partner) {
    final actor = _currentParticipant;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        _proposalDialogContext = dialogCtx;
        return ProposeExchangeDialog(
          partner: partner,
          userSkillsToShare: widget.userSkillsToShare,
          existingProposals: _myExchanges,
          onSubmit: (offeredSkill, wantedSkill, note) {
            if (!mounted ||
                !widget.isLearningActivated ||
                widget.isUnavailable ||
                widget.currentUserId != actor.learningProfileId ||
                widget.currentAccountId != actor.accountId) return;
            final newExchange = SkillExchange.propose(
              id: 'ex_${DateTime.now().millisecondsSinceEpoch}',
              sender: _currentParticipant,
              recipient: partner.toParticipant(),
              offeredSkill: offeredSkill,
              wantedSkill: wantedSkill,
              note: note,
              existingProposals: _myExchanges,
            );

            setState(() {
              _myExchanges.insert(0, newExchange);
              _confirmationBannerMessage =
                  'Skill exchange proposal sent to ${partner.displayName}.';
            });
          },
        );
      },
    ).whenComplete(() => _proposalDialogContext = null);
  }

  void _handleCancelExchange(SkillExchange exchange) {
    setState(() {
      final index = _myExchanges.indexWhere((e) => e.id == exchange.id);
      if (index != -1) {
        _myExchanges[index] = exchange.cancel(_currentParticipant);
        _confirmationBannerMessage = 'Proposal cancelled successfully.';
      }
    });
  }

  void _handleAcceptExchange(SkillExchange exchange) {
    setState(() {
      final index = _myExchanges.indexWhere((e) => e.id == exchange.id);
      if (index != -1) {
        _myExchanges[index] = exchange.accept(_currentParticipant);
        _confirmationBannerMessage =
            'Proposal accepted! Mutual agreement active.';
      }
    });
  }

  void _handleDeclineExchange(SkillExchange exchange) {
    setState(() {
      final index = _myExchanges.indexWhere((e) => e.id == exchange.id);
      if (index != -1) {
        _myExchanges[index] = exchange.decline(_currentParticipant);
        _confirmationBannerMessage = 'Proposal declined.';
      }
    });
  }

  List<SkillPartner> _getFilteredPartners() {
    final query = _searchController.text.trim().toLowerCase();

    return _partners.where((partner) {
      // Exclude oneself
      if (partner.profileId == widget.currentUserId) {
        return false;
      }

      // Category filter
      if (_selectedCategory != 'All' && partner.category != _selectedCategory) {
        return false;
      }

      // Offer quick filter: partner wants skills that current user can share
      if (_filterOfferOnly) {
        final matches = partner.skillsWanted.any((wanted) =>
            widget.userSkillsToShare.any((userSkill) =>
                wanted.toLowerCase().contains(userSkill.toLowerCase()) ||
                userSkill.toLowerCase().contains(wanted.toLowerCase())));
        if (!matches) return false;
      }

      // Learn quick filter: partner offers skills that current user wants to learn
      if (_filterLearnOnly) {
        final matches = partner.skillsOffered.any((offered) =>
            widget.userSkillsToLearn.any((userSkill) =>
                offered.toLowerCase().contains(userSkill.toLowerCase()) ||
                userSkill.toLowerCase().contains(offered.toLowerCase())));
        if (!matches) return false;
      }

      // Text query search
      if (query.isNotEmpty) {
        final nameMatch = partner.displayName.toLowerCase().contains(query);
        final categoryMatch = partner.category.toLowerCase().contains(query);
        final offeredMatch =
            partner.skillsOffered.any((s) => s.toLowerCase().contains(query));
        final wantedMatch =
            partner.skillsWanted.any((s) => s.toLowerCase().contains(query));
        return nameMatch || categoryMatch || offeredMatch || wantedMatch;
      }

      return true;
    }).toList();
  }

  String _resolvePartnerName(SkillExchange exchange) {
    final partnerId = exchange.sender.learningProfileId == widget.currentUserId
        ? exchange.recipient.learningProfileId
        : exchange.sender.learningProfileId;

    final found = _partners.cast<SkillPartner?>().firstWhere(
          (p) => p?.profileId == partnerId,
          orElse: () => null,
        );
    return found?.displayName ?? 'Learner ($partnerId)';
  }

  @override
  Widget build(BuildContext context) {
    // Gate 1: Fail-closed access denial
    if (!widget.isLearningActivated ||
        (!widget.isUnavailable &&
            (widget.currentUserId.trim().isEmpty ||
                widget.currentAccountId.trim().isEmpty))) {
      return Scaffold(
        backgroundColor: LearningColors.background,
        appBar: _buildAppBar(),
        body: _buildAccessDeniedView(),
      );
    }

    // Gate 2: Loading State
    if (widget.isLoading) {
      return Scaffold(
        backgroundColor: LearningColors.background,
        appBar: _buildAppBar(),
        body: const Center(
          key: ValueKey('indicator_hub_loading'),
          child: CircularProgressIndicator(color: LearningColors.primary),
        ),
      );
    }

    // Gate 3: Error State with Retry
    if (widget.errorMessage != null) {
      return Scaffold(
        backgroundColor: LearningColors.background,
        appBar: _buildAppBar(),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ErrorRetryCard(
              key: const ValueKey('card_hub_error'),
              title: 'Unable to load Skill Exchange',
              message: widget.errorMessage!,
              onRetry: widget.onRetry,
            ),
          ),
        ),
      );
    }

    // Gate 4: Unavailable State
    if (widget.isUnavailable) {
      return Scaffold(
        backgroundColor: LearningColors.background,
        appBar: _buildAppBar(),
        body: _buildUnavailableView(),
      );
    }

    final filteredPartners = _getFilteredPartners();
    final activeProposalCount = _myExchanges
        .where((e) => e.status == SkillExchangeStatus.pending)
        .length;

    return Scaffold(
      backgroundColor: LearningColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Disconnected Persistence Disclaimer Banner
            Container(
              key: const ValueKey('banner_disconnected_notice'),
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: const Color(0xFFE0E7FF),
              child: const Row(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 16,
                    color: LearningColors.primary,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      SkillExchange.disconnectedNotice,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: LearningColors.heading,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Confirmation Status Banner
            if (_confirmationBannerMessage != null) ...[
              Container(
                key: const ValueKey('banner_confirmation'),
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                color: const Color(0xFFDCFCE7),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Color(0xFF15803D),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _confirmationBannerMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () {
                        setState(() {
                          _confirmationBannerMessage = null;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8.0),

            // Navigation Segmented Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      key: const ValueKey('tab_discover_partners'),
                      onPressed: () {
                        setState(() {
                          _selectedTabIndex = 0;
                        });
                      },
                      icon: const Icon(Icons.people_outline_rounded, size: 16),
                      label: const Text('Discover Partners'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedTabIndex == 0
                            ? LearningColors.primary
                            : LearningColors.cardSurface,
                        foregroundColor: _selectedTabIndex == 0
                            ? Colors.white
                            : LearningColors.heading,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side: BorderSide(
                            color: _selectedTabIndex == 0
                                ? LearningColors.primary
                                : Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: ElevatedButton.icon(
                      key: const ValueKey('tab_my_exchanges'),
                      onPressed: () {
                        setState(() {
                          _selectedTabIndex = 1;
                        });
                      },
                      icon: Badge(
                        isLabelVisible: activeProposalCount > 0,
                        label: Text('$activeProposalCount'),
                        child: const Icon(Icons.swap_horiz_rounded, size: 16),
                      ),
                      label: const Text('My Exchanges'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedTabIndex == 1
                            ? LearningColors.primary
                            : LearningColors.cardSurface,
                        foregroundColor: _selectedTabIndex == 1
                            ? Colors.white
                            : LearningColors.heading,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side: BorderSide(
                            color: _selectedTabIndex == 1
                                ? LearningColors.primary
                                : Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12.0),

            // Tab View Body
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildDiscoverView(filteredPartners)
                  : _buildMyExchangesView(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      actions: [
        if (widget.onOpenPacts != null)
          IconButton(
            tooltip: 'Learning Pacts',
            onPressed: widget.onOpenPacts,
            icon: const Icon(Icons.handshake_outlined),
          ),
      ],
      backgroundColor: LearningColors.background,
      elevation: 0,
      centerTitle: false,
      leading: widget.onBack != null
          ? IconButton(
              key: const ValueKey('btn_app_bar_back'),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: LearningColors.heading,
              ),
              onPressed: widget.onBack,
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Flexible(
            child: Text(
              'Skill Exchange Hub',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: LearningColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: const Text(
              'Learning',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: LearningColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverView(List<SkillPartner> filteredPartners) {
    return Column(
      children: [
        SkillFilterBar(
          searchController: _searchController,
          selectedCategory: _selectedCategory,
          filterOfferOnly: _filterOfferOnly,
          filterLearnOnly: _filterLearnOnly,
          onSearchChanged: (_) => setState(() {}),
          onClearSearch: () {
            setState(() {
              _searchController.clear();
            });
          },
          onCategorySelected: (cat) {
            setState(() {
              _selectedCategory = cat;
            });
          },
          onToggleOfferFilter: () {
            setState(() {
              _filterOfferOnly = !_filterOfferOnly;
            });
          },
          onToggleLearnFilter: () {
            setState(() {
              _filterLearnOnly = !_filterLearnOnly;
            });
          },
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: filteredPartners.isEmpty
              ? _buildEmptyPartnersView()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  itemCount: filteredPartners.length,
                  itemBuilder: (context, index) {
                    final partner = filteredPartners[index];
                    final hasPending = _myExchanges.any((e) =>
                        e.status == SkillExchangeStatus.pending &&
                        (e.sender.learningProfileId == partner.profileId ||
                            e.recipient.learningProfileId ==
                                partner.profileId));

                    return SkillPartnerCard(
                      partner: partner,
                      hasPendingExchangeWithUser: hasPending,
                      onRequestExchange: _handleProposeExchange,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMyExchangesView() {
    if (_myExchanges.isEmpty) {
      return _buildEmptyExchangesView();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24.0),
      itemCount: _myExchanges.length,
      itemBuilder: (context, index) {
        final exchange = _myExchanges[index];
        final partnerName = _resolvePartnerName(exchange);

        return SkillExchangeCard(
          exchange: exchange,
          currentProfileId: widget.currentUserId,
          partnerDisplayName: partnerName,
          onCancel: _handleCancelExchange,
          onAccept: _handleAcceptExchange,
          onDecline: _handleDeclineExchange,
        );
      },
    );
  }

  Widget _buildEmptyPartnersView() {
    return Center(
      key: const ValueKey('view_empty_partners'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: LearningColors.secondaryText.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12.0),
            const Text(
              'No Matching Partners Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 6.0),
            const Text(
              'Try clearing search keywords or category filters to explore more learning opportunities.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: LearningColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16.0),
            OutlinedButton.icon(
              key: const ValueKey('btn_reset_partner_filters'),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedCategory = 'All';
                  _filterOfferOnly = false;
                  _filterLearnOnly = false;
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset All Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyExchangesView() {
    return Center(
      key: const ValueKey('view_empty_exchanges'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              size: 56,
              color: LearningColors.secondaryText.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12.0),
            const Text(
              'No Skill Exchanges Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: LearningColors.heading,
              ),
            ),
            const SizedBox(height: 6.0),
            const Text(
              'Discover partners in the learning community and propose a reciprocal skill exchange.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: LearningColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              key: const ValueKey('btn_go_discover_partners'),
              onPressed: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
              },
              icon: const Icon(Icons.people_outline_rounded, size: 16),
              label: const Text('Discover Partners'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDeniedView() {
    return Center(
      key: const ValueKey('card_hub_access_denied'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: LearningColors.cardSurface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: _errorColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: _errorColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: _errorColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14.0),
              const Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Authenticated Learning profile ownership and module activation are required to access the Skill Exchange Hub.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: LearningColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnavailableView() {
    return Center(
      key: const ValueKey('card_hub_unavailable'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: LearningColors.cardSurface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pause_circle_outline_rounded,
                  color: Colors.amber.shade800,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14.0),
              const Text(
                'Skill Exchange Temporarily Unavailable',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LearningColors.heading,
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Skill exchange is not connected yet. Requests cannot be sent or changed right now.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: LearningColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
