import 'package:flutter/material.dart';

import 'package:andril_mobile/app/themes/learning/learning_colors.dart';
import 'package:andril_mobile/features/shared/presentation/widgets/error_retry_card.dart';
import '../../domain/entities/classroom_join_request.dart';
import '../../domain/entities/learning_classroom.dart';
import '../widgets/classroom_card.dart';
import '../widgets/classroom_filter_bar.dart';
import '../widgets/create_classroom_dialog.dart';
import '../widgets/host_classroom_requests_dialog.dart';
import '../widgets/request_to_join_dialog.dart';

/// Presentation screen for Learning Classrooms Hub & Discovery (CF-06 / CF-07, BRD v2.4-R1, pages 7 and 15).
///
/// Features:
/// - All Classrooms discovery view and My Classrooms view.
/// - Keyword search across classroom name, description, tags, and host.
/// - Category filtering with responsive chips.
/// - Privacy badges (Public, Approval Required, Private).
/// - Instant join for public classrooms and admission request dialog for approval-required classrooms.
/// - Disconnected persistence disclaimer banner.
/// - Fail-closed security: unauthenticated or unactivated callers are denied access.
/// - Session revocation: switching [currentUserId] instantly purges all dirty state.
class LearningClassroomsHubScreen extends StatefulWidget {
  final String currentUserId;
  final String currentAccountId;
  final String currentDisplayName;
  final bool isLearningActivated;
  final bool isLoading;
  final String? errorMessage;
  final bool isUnavailable;
  final List<LearningClassroom>? initialClassrooms;
  final VoidCallback? onBack;
  final VoidCallback? onRetry;

  const LearningClassroomsHubScreen({
    super.key,
    required this.currentUserId,
    this.currentAccountId = 'acc_current_user',
    this.currentDisplayName = 'Thusa Learner',
    this.isLearningActivated = true,
    this.isLoading = false,
    this.errorMessage,
    this.isUnavailable = false,
    this.initialClassrooms,
    this.onBack,
    this.onRetry,
  });

  @override
  State<LearningClassroomsHubScreen> createState() =>
      _LearningClassroomsHubScreenState();
}

class _LearningClassroomsHubScreenState
    extends State<LearningClassroomsHubScreen> {
  int _selectedTabIndex = 0; // 0 = All Classrooms, 1 = My Classrooms
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  late List<LearningClassroom> _classrooms;
  final List<ClassroomJoinRequest> _pendingRequests = [];
  final Map<String, List<ClassroomJoinRequest>> _hostAdmissionRequests = {};
  String? _confirmationBannerMessage;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    _classrooms =
        List.of(widget.initialClassrooms ?? LearningClassroom.sampleClassrooms);
    _hostAdmissionRequests.clear();
    // Seed sample pending admission request for hosted classroom to enable host review workflow
    _hostAdmissionRequests['cls_my_mentorship_classroom_06'] = [
      ClassroomJoinRequest.create(
        requestId: 'req_seed_host_01',
        classroomId: 'cls_my_mentorship_classroom_06',
        applicantProfileId: 'prof_applicant_charlie',
        note: 'Looking forward to participating in the architecture labs.',
      ),
    ];
  }

  @override
  void didUpdateWidget(LearningClassroomsHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Session revocation: Purge state immediately when caller ID changes.
    if (widget.currentUserId != oldWidget.currentUserId) {
      _searchController.clear();
      _selectedCategory = 'All';
      _selectedTabIndex = 0;
      _confirmationBannerMessage = null;
      _pendingRequests.clear();
      _hostAdmissionRequests.clear();
      _initData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleJoinPublicClassroom(LearningClassroom classroom) {
    setState(() {
      final index = _classrooms.indexWhere((c) => c.id == classroom.id);
      if (index != -1) {
        _classrooms[index] = classroom.copyWith(
          membershipStatus: ClassroomMembershipStatus.member,
          memberCount: classroom.memberCount + 1,
        );
        _confirmationBannerMessage = 'Joined "${classroom.name}" successfully.';
      }
    });
  }

  void _handleRequestToJoin(LearningClassroom classroom) {
    showDialog(
      context: context,
      builder: (dialogCtx) => RequestToJoinDialog(
        classroom: classroom,
        onSubmit: (note) {
          final request = ClassroomJoinRequest.create(
            requestId: 'req_${DateTime.now().millisecondsSinceEpoch}',
            classroomId: classroom.id,
            applicantProfileId: widget.currentUserId,
            note: note,
          );

          setState(() {
            _pendingRequests.add(request);
            final index = _classrooms.indexWhere((c) => c.id == classroom.id);
            if (index != -1) {
              _classrooms[index] = classroom.copyWith(
                membershipStatus: ClassroomMembershipStatus.pending,
              );
            }
            _confirmationBannerMessage =
                'Admission request submitted for "${classroom.name}".';
          });
        },
      ),
    );
  }

  void _handleCancelRequest(LearningClassroom classroom) {
    setState(() {
      final reqIndex =
          _pendingRequests.indexWhere((r) => r.classroomId == classroom.id);
      if (reqIndex != -1) {
        _pendingRequests.removeAt(reqIndex);
      }
      final index = _classrooms.indexWhere((c) => c.id == classroom.id);
      if (index != -1) {
        _classrooms[index] = classroom.copyWith(
          membershipStatus: ClassroomMembershipStatus.none,
        );
      }
      _confirmationBannerMessage = 'Admission request cancelled.';
    });
  }

  void _openCreateClassroomDialog() {
    CreateClassroomDialog.show(
      context,
      onCreate: ({
        required String name,
        required String description,
        required String category,
        required ClassroomPrivacy privacy,
        int? capacity,
        List<String> tags = const [],
      }) async {
        final newClassroom = LearningClassroom.create(
          id: 'cls_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          description: description,
          category: category,
          privacy: privacy,
          memberCount: 1,
          capacity: capacity,
          hostProfileId: widget.currentUserId,
          hostDisplayName: widget.currentDisplayName,
          membershipStatus: ClassroomMembershipStatus.host,
          tags: tags,
          isDiscoverable: privacy != ClassroomPrivacy.closed,
          createdAt: DateTime.now(),
        );

        setState(() {
          _classrooms.insert(0, newClassroom);
          _confirmationBannerMessage =
              'Classroom "$name" created successfully.';
        });
        return true;
      },
    );
  }

  void _handleManageHostRequests(LearningClassroom classroom) {
    final requests = List<ClassroomJoinRequest>.of(
        _hostAdmissionRequests[classroom.id] ?? const []);
    HostClassroomRequestsDialog.show(
      context,
      classroom: classroom,
      pendingRequests: requests,
      onApprove: (req) {
        setState(() {
          _hostAdmissionRequests[classroom.id]
              ?.removeWhere((r) => r.requestId == req.requestId);
          final idx = _classrooms.indexWhere((c) => c.id == classroom.id);
          if (idx != -1) {
            final current = _classrooms[idx];
            _classrooms[idx] = current.copyWith(
              memberCount: current.memberCount + 1,
            );
          }
          _confirmationBannerMessage =
              'Approved applicant for "${classroom.name}".';
        });
      },
      onDecline: (req) {
        setState(() {
          _hostAdmissionRequests[classroom.id]
              ?.removeWhere((r) => r.requestId == req.requestId);
          _confirmationBannerMessage =
              'Declined applicant request for "${classroom.name}".';
        });
      },
    );
  }

  List<LearningClassroom> _getFilteredClassrooms() {
    final query = _searchController.text.trim().toLowerCase();

    return _classrooms.where((classroom) {
      // Tab filter
      if (_selectedTabIndex == 1 && !classroom.isEnrolled) {
        return false;
      }

      // Category filter
      if (_selectedCategory.toLowerCase() != 'all' &&
          classroom.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }

      // Search keyword filter
      if (query.isNotEmpty) {
        final matchesName = classroom.name.toLowerCase().contains(query);
        final matchesDesc = classroom.description.toLowerCase().contains(query);
        final matchesHost =
            classroom.hostDisplayName.toLowerCase().contains(query);
        final matchesTags =
            classroom.tags.any((t) => t.toLowerCase().contains(query));
        if (!matchesName && !matchesDesc && !matchesHost && !matchesTags) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Fail-closed access denial check
    if (widget.currentUserId.trim().isEmpty || !widget.isLearningActivated) {
      return _buildAccessDeniedView();
    }

    // Loading state
    if (widget.isLoading) {
      return _buildScaffold(
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Error state
    if (widget.errorMessage != null) {
      return _buildScaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ErrorRetryCard(
              title: 'Error Loading Classrooms',
              message: widget.errorMessage!,
              onRetry: widget.onRetry,
            ),
          ),
        ),
      );
    }

    // Unavailable state
    if (widget.isUnavailable) {
      return _buildScaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: 48.0,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Classrooms Service Unavailable',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'The classrooms service is currently offline or undergoing scheduled maintenance. Please check back later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                if (widget.onRetry != null) ...[
                  const SizedBox(height: 16.0),
                  ElevatedButton.icon(
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Connection'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final filteredClassrooms = _getFilteredClassrooms();

    return _buildScaffold(
      body: Column(
        children: [
          // Disconnected Persistence Disclaimer Notice Banner
          _buildNoticeBanner(),

          // Confirmation Banner
          if (_confirmationBannerMessage != null) _buildConfirmationBanner(),

          // Navigation Toggle (All Classrooms vs My Classrooms)
          _buildViewToggle(),

          // Search and Category Filter Bar
          ClassroomFilterBar(
            searchController: _searchController,
            onSearchChanged: (_) => setState(() {}),
            onClearSearch: () {
              _searchController.clear();
              setState(() {});
            },
            selectedCategory: _selectedCategory,
            onCategorySelected: (cat) {
              setState(() {
                _selectedCategory = cat;
              });
            },
          ),

          // Classroom List or Empty State
          Expanded(
            child: filteredClassrooms.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: filteredClassrooms.length,
                    itemBuilder: (ctx, index) {
                      final classroom = filteredClassrooms[index];
                      return ClassroomCard(
                        classroom: classroom,
                        onJoin: () => _handleJoinPublicClassroom(classroom),
                        onRequestToJoin: () => _handleRequestToJoin(classroom),
                        onCancelRequest: () => _handleCancelRequest(classroom),
                        onManageRequests: classroom.membershipStatus ==
                                ClassroomMembershipStatus.host
                            ? () => _handleManageHostRequests(classroom)
                            : null,
                        pendingRequestsCount:
                            _hostAdmissionRequests[classroom.id]?.length ?? 0,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaffold({required Widget body}) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
                tooltip: 'Back',
              )
            : null,
        title: const Text(
          'Classrooms Hub',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton.icon(
            key: const ValueKey('btn_appbar_create_classroom'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create'),
            style: TextButton.styleFrom(
              foregroundColor: LearningColors.primary,
            ),
            onPressed: _openCreateClassroomDialog,
          ),
        ],
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: body,
    );
  }

  Widget _buildNoticeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: const Color(0xFFFEF3C7),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16.0, color: Color(0xFF92400E)),
          SizedBox(width: 8.0),
          Expanded(
            child: Text(
              LearningClassroom.disconnectedNotice,
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF92400E),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: const Color(0xFFD1FAE5),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 16.0, color: Color(0xFF065F46)),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _confirmationBannerMessage!,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF065F46),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16.0, color: Color(0xFF065F46)),
            onPressed: () => setState(() => _confirmationBannerMessage = null),
            tooltip: 'Dismiss',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
      child: Container(
        height: 40.0,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = 0),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == 0
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7.0),
                    boxShadow: _selectedTabIndex == 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4.0,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'All Classrooms',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: _selectedTabIndex == 0
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: _selectedTabIndex == 0
                          ? LearningColors.primary
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = 1),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == 1
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7.0),
                    boxShadow: _selectedTabIndex == 1
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4.0,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'My Classrooms',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: _selectedTabIndex == 1
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: _selectedTabIndex == 1
                          ? LearningColors.primary
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isMyClassrooms = _selectedTabIndex == 1;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMyClassrooms ? Icons.school_outlined : Icons.search_off,
              size: 48.0,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16.0),
            Text(
              isMyClassrooms ? 'No Enrolled Classrooms' : 'No Classrooms Found',
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              isMyClassrooms
                  ? 'You have not joined or hosted any classrooms yet. Explore the All Classrooms tab to discover active learning communities.'
                  : 'No classrooms matched your current filter or search criteria. Try a different topic or category.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.0,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            if (isMyClassrooms) ...[
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedTabIndex = 0),
                icon: const Icon(Icons.explore, size: 18.0),
                label: const Text('Discover Classrooms'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDeniedView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Classrooms Hub'),
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 48.0,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Learning Profile Required',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Access to Classrooms Hub requires an authenticated and activated Learning profile. Complete onboarding to discover, join, and collaborate in classrooms.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
