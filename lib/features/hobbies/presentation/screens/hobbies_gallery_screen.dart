import 'package:flutter/material.dart';

import '../../../../app/themes/hobbies/hobbies_colors.dart';
import '../../../../app/themes/hobbies/hobbies_theme.dart';
import '../../../../app/themes/hobbies/hobbies_typography.dart';
import '../widgets/andril_hobbies_scaffold.dart';

/// Available presentation states for [HobbiesGalleryScreen].
enum HobbiesGalleryStatus {
  /// Gallery content is being retrieved.
  loading,

  /// The gallery was retrieved successfully but contains zero items.
  empty,

  /// The gallery contains authorized media items to display.
  populated,

  /// Access to the gallery is not authorized or denied by policy.
  denied,

  /// An unexpected error occurred while loading gallery media.
  error,
}

/// Presentation model representing an item in the Hobbies Media Gallery.
///
/// Encapsulates display-only properties for media thumbnails, captions, and tags.
///
/// Architectural & Privacy Boundaries:
/// - Isolated to the Hobbies module; must never reveal Learning or Dating profile identities.
/// - Distinct from HOB-03 Andril Map contributions (which require fresh in-app camera capture and moderation).
/// - Excludes Hobbies Photo Portfolios (which are permanently excluded per BRD v2.4-R1).
class HobbiesGalleryItem {
  /// Unique identifier for the media item.
  final String id;

  /// Human-readable title of the hobby media item.
  final String title;

  /// Optional descriptive caption or hobby milestone note.
  final String? caption;

  /// Optional media URI or thumbnail reference.
  final String? mediaUrl;

  /// Optional associated hobby category or tag (e.g., 'Pottery', 'Gardening').
  final String? hobbyTag;

  /// Timestamp when the media was recorded or uploaded.
  final DateTime? createdAt;

  /// Creates a [HobbiesGalleryItem].
  const HobbiesGalleryItem({
    required this.id,
    required this.title,
    this.caption,
    this.mediaUrl,
    this.hobbyTag,
    this.createdAt,
  });
}

/// Explicitly labeled mock fixtures for development and widget testing.
///
/// These items are presentation-only placeholders and must never be treated
/// as production persistence or real user profile media.
abstract final class HobbiesGalleryMockFixtures {
  HobbiesGalleryMockFixtures._();

  /// Standard development mock items for testing gallery presentation.
  static final List<HobbiesGalleryItem> sampleItems = <HobbiesGalleryItem>[
    HobbiesGalleryItem(
      id: 'mock-hob-01',
      title: 'Ceramic Glazing Workshop',
      caption: 'Testing cobalt blue glaze at 1200 degrees.',
      hobbyTag: 'Pottery',
      createdAt: DateTime(2026, 11, 20),
    ),
    HobbiesGalleryItem(
      id: 'mock-hob-02',
      title: 'Macro Orchid Bloom',
      caption: 'First bloom after two seasons of care.',
      hobbyTag: 'Gardening',
      createdAt: DateTime(2026, 11, 21),
    ),
    HobbiesGalleryItem(
      id: 'mock-hob-03',
      title: 'Handmade Leather Journal',
      caption: 'Vegetable-tanned leather binding with saddle stitch.',
      hobbyTag: 'Crafts',
      createdAt: DateTime(2026, 11, 22),
    ),
    HobbiesGalleryItem(
      id: 'mock-hob-04',
      title: 'Sourdough Country Loaf',
      caption: '80% hydration with open crumb texture.',
      hobbyTag: 'Baking',
      createdAt: DateTime(2026, 11, 23),
    ),
  ];
}

/// Reusable Hobbies Media Gallery screen implementing checkpoint M3-CP-02A.
///
/// Features:
/// - Reuses [AndrilHobbiesScaffold] with approved Hobbies branding and decorative wave header.
/// - Enforces [HobbiesTheme.lightTheme] and approved [HobbiesColors].
/// - Displays branded screen title, explanatory subtitle, and feature disclaimer banner.
/// - Provides metrics counters (Total Media | Visible Media).
/// - Includes a visible but disabled upload entry point indicating backend integration is pending.
/// - Presents responsive grid layout, loading, empty, denied-access, and error states.
/// - Touch-friendly interactive item callbacks and retry controls.
/// - Responsive across compact (320x568) and standard viewports with dynamic text scaling.
class HobbiesGalleryScreen extends StatelessWidget {
  /// Unique screen identifier matching project tracking specification.
  static const String screenId = 'M3-HOB-01-GALLERY-01';

  /// Standard screen title.
  static const String defaultTitle = 'Hobbies Media Gallery';

  /// Standard explanatory subtitle.
  static const String defaultSubtitle =
      'Manage and showcase your hobby photos and creative media.';

  /// Mandatory business disclaimer text.
  static const String disclaimerText =
      'This screen is for general Hobbies photos and media. Photo Portfolios are not part of this feature.';

  /// Notice displayed on the upload entry point.
  static const String uploadUnavailableNotice =
      'Upload integration is not yet available.';

  /// Title displayed in the app bar.
  final String title;

  /// Explanatory subtitle displayed below the screen header.
  final String subtitle;

  /// Current presentation status of the gallery.
  final HobbiesGalleryStatus status;

  /// Media items to display when [status] is [HobbiesGalleryStatus.populated].
  final List<HobbiesGalleryItem> items;

  /// Callback invoked when the user taps the retry button in an error state.
  final VoidCallback? onRetry;

  /// Optional callback invoked when the user taps the upload action.
  final VoidCallback? onUploadPressed;

  /// Optional callback invoked when the user taps a gallery thumbnail card.
  final void Function(HobbiesGalleryItem item)? onItemTapped;

  /// Custom error message to display when [status] is [HobbiesGalleryStatus.error].
  final String? errorMessage;

  /// Custom denied message to display when [status] is [HobbiesGalleryStatus.denied].
  final String? deniedMessage;

  /// Whether the upload button is enabled (defaults to false for presentation checkpoint).
  final bool isUploadEnabled;

  /// Whether the upload action is authorized to execute in the current presentation state.
  ///
  /// Enforces fail-closed privacy rules: when the gallery is in [HobbiesGalleryStatus.denied],
  /// [HobbiesGalleryStatus.loading], or [HobbiesGalleryStatus.error], the upload action
  /// cannot be invoked even if [isUploadEnabled] is true.
  bool get canUpload =>
      isUploadEnabled &&
      (status == HobbiesGalleryStatus.populated ||
          status == HobbiesGalleryStatus.empty);

  /// Whether the gallery metrics card is authorized to be displayed.
  ///
  /// Enforces fail-closed privacy rules: only [HobbiesGalleryStatus.populated] and
  /// [HobbiesGalleryStatus.empty] states are authorized to display Gallery metrics.
  /// Denied, loading, and error states must never expose private metrics or item counts.
  bool get showMetrics =>
      status == HobbiesGalleryStatus.populated ||
      status == HobbiesGalleryStatus.empty;

  /// Creates a [HobbiesGalleryScreen].
  const HobbiesGalleryScreen({
    super.key,
    this.title = defaultTitle,
    this.subtitle = defaultSubtitle,
    this.status = HobbiesGalleryStatus.empty,
    this.items = const <HobbiesGalleryItem>[],
    this.onRetry,
    this.onUploadPressed,
    this.onItemTapped,
    this.errorMessage,
    this.deniedMessage,
    this.isUploadEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return AndrilHobbiesScaffold(
      title: title,
      showWave: true,
      body: CustomScrollView(
        key: const Key('hobbies_gallery_scroll_view'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: <Widget>[
          // Header section: Subtitle, Disclaimer Banner, Metrics, and Upload Entry
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 8.0),

                  // Explanatory Subtitle
                  Text(
                    subtitle,
                    style: HobbiesTypography.secondaryText.copyWith(
                      color: HobbiesTheme.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 10.0),

                  // Feature Disclaimer Banner (Excludes Photo Portfolios)
                  _buildDisclaimerBanner(context),

                  const SizedBox(height: 12.0),

                  // Metrics Summary & Add Media Action Row
                  _buildMetricsAndUploadRow(context),

                  const SizedBox(height: 14.0),
                ],
              ),
            ),
          ),

          // Main Content Area: Responsive Grid or Dedicated Status States
          ..._buildStatusSlivers(context),

          // Bottom safe padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 24.0),
          ),
        ],
      ),
    );
  }

  /// Builds the mandatory feature disclaimer notice.
  Widget _buildDisclaimerBanner(BuildContext context) {
    return Container(
      key: const Key('gallery_disclaimer_banner'),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: HobbiesTheme.cardSurface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFFA7F3D0), // Soft mint border
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF0D9488), // Teal-600
            size: 20.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              disclaimerText,
              style: HobbiesTypography.caption.copyWith(
                color: HobbiesTheme.textDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the dual metric cards and upload action row with responsive adaptation
  /// and fail-closed privacy protections.
  Widget _buildMetricsAndUploadRow(BuildContext context) {
    // Fail-closed metric counts: Empty state strictly displays zero metrics even if
    // stale items are supplied. Denied, loading, and error states do not show metrics.
    final int totalCount =
        status == HobbiesGalleryStatus.populated ? items.length : 0;
    final int visibleCount =
        status == HobbiesGalleryStatus.populated ? items.length : 0;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 420;

        final Widget uploadButton = Tooltip(
          message: uploadUnavailableNotice,
          child: SizedBox(
            width: (isCompact || !showMetrics) ? double.infinity : null,
            child: ElevatedButton.icon(
              key: const Key('gallery_upload_button'),
              onPressed: canUpload ? onUploadPressed : null,
              icon: const Icon(Icons.cloud_upload_outlined, size: 18.0),
              label: const Text('Add Media'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 12.0,
                ),
              ),
            ),
          ),
        );

        if (!showMetrics) {
          return uploadButton;
        }

        final Widget metricsCard = Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14.0,
            vertical: 8.0,
          ),
          decoration: BoxDecoration(
            color: HobbiesTheme.cardSurface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: const Color(0xFFD1FAE5),
              width: 1.0,
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '$totalCount',
                      style: HobbiesTypography.sectionTitle.copyWith(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: HobbiesTheme.textDark,
                      ),
                    ),
                    Text(
                      'Total Media',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HobbiesTypography.caption.copyWith(
                        color: HobbiesTheme.textSecondary,
                        fontSize: 11.0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 24.0,
                width: 1.0,
                color: const Color(0xFFD1FAE5),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '$visibleCount',
                      style: HobbiesTypography.sectionTitle.copyWith(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: HobbiesTheme.textDark,
                      ),
                    ),
                    Text(
                      'Visible Media',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HobbiesTypography.caption.copyWith(
                        color: HobbiesTheme.textSecondary,
                        fontSize: 11.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (isCompact) {
          return Column(
            children: <Widget>[
              metricsCard,
              const SizedBox(height: 8.0),
              uploadButton,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: metricsCard),
            const SizedBox(width: 10.0),
            uploadButton,
          ],
        );
      },
    );
  }

  /// Dispatches the appropriate sliver widgets based on the active [status].
  List<Widget> _buildStatusSlivers(BuildContext context) {
    switch (status) {
      case HobbiesGalleryStatus.loading:
        return <Widget>[
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _GalleryLoadingState(),
          ),
        ];

      case HobbiesGalleryStatus.empty:
        return <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: _GalleryEmptyState(
              onAddMedia: canUpload ? onUploadPressed : null,
            ),
          ),
        ];

      case HobbiesGalleryStatus.denied:
        return <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: _GalleryDeniedState(
              message: deniedMessage,
            ),
          ),
        ];

      case HobbiesGalleryStatus.error:
        return <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: _GalleryErrorState(
              message: errorMessage,
              onRetry: onRetry,
            ),
          ),
        ];

      case HobbiesGalleryStatus.populated:
        return <Widget>[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final HobbiesGalleryItem item = items[index];
                  return _GalleryGridCard(
                    item: item,
                    onTap:
                        onItemTapped != null ? () => onItemTapped!(item) : null,
                  );
                },
                childCount: items.length,
              ),
            ),
          ),
        ];
    }
  }
}

/// Individual media card rendered inside the populated gallery grid.
class _GalleryGridCard extends StatelessWidget {
  final HobbiesGalleryItem item;
  final VoidCallback? onTap;

  const _GalleryGridCard({
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hobbies media item: ${item.title}',
      button: onTap != null,
      child: Material(
        color: HobbiesTheme.cardSurface,
        borderRadius: BorderRadius.circular(14.0),
        elevation: 0.0,
        child: InkWell(
          key: Key('gallery_item_${item.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Thumbnail container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9), // Slate-100 placeholder
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(13.0),
                      ),
                    ),
                    child: Stack(
                      children: <Widget>[
                        Center(
                          child: Icon(
                            Icons.photo_outlined,
                            size: 36.0,
                            color: HobbiesColors.primary.withAlpha(180),
                          ),
                        ),
                        if (item.hobbyTag != null)
                          Positioned(
                            top: 8.0,
                            left: 8.0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: HobbiesColors.background,
                                borderRadius: BorderRadius.circular(6.0),
                                border: Border.all(
                                  color: HobbiesColors.primary.withAlpha(80),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                item.hobbyTag!,
                                style: HobbiesTypography.caption.copyWith(
                                  color: HobbiesTheme.textDark,
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Content label section
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HobbiesTypography.buttonLabel.copyWith(
                          color: HobbiesTheme.textDark,
                          fontSize: 13.0,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        item.caption ?? 'Hobbies moment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HobbiesTypography.caption.copyWith(
                          color: HobbiesTheme.textSecondary,
                          fontSize: 11.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading state widget presenting accessible progress indication.
class _GalleryLoadingState extends StatelessWidget {
  const _GalleryLoadingState();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading gallery items',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(HobbiesColors.primary),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Loading media gallery...',
                style: HobbiesTypography.secondaryText.copyWith(
                  color: HobbiesTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state widget displaying clear guidance when zero media exists.
class _GalleryEmptyState extends StatelessWidget {
  final VoidCallback? onAddMedia;

  const _GalleryEmptyState({this.onAddMedia});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Empty gallery: No hobby moments yet',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32.0,
            vertical: 40.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 88.0,
                height: 88.0,
                decoration: BoxDecoration(
                  color: HobbiesColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: HobbiesColors.primary.withAlpha(60),
                    width: 2.0,
                  ),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  size: 42.0,
                  color: HobbiesColors.primary,
                ),
              ),
              const SizedBox(height: 18.0),
              Text(
                'No Hobby Moments Yet',
                style: HobbiesTypography.sectionTitle.copyWith(
                  color: HobbiesTheme.textDark,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Capture and showcase your hobby milestones, projects, and creative activities in your personal gallery.',
                textAlign: TextAlign.center,
                style: HobbiesTypography.bodyText.copyWith(
                  color: HobbiesTheme.textSecondary,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton.icon(
                key: const Key('gallery_empty_add_button'),
                onPressed: onAddMedia,
                icon:
                    const Icon(Icons.add_photo_alternate_outlined, size: 18.0),
                label: const Text('Add First Moment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Denied-access state widget when permission is unauthorized.
class _GalleryDeniedState extends StatelessWidget {
  final String? message;

  const _GalleryDeniedState({this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Access Denied: Permission required to view gallery',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32.0,
            vertical: 40.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 76.0,
                height: 76.0,
                decoration: BoxDecoration(
                  color: HobbiesTheme.errorColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 38.0,
                  color: HobbiesTheme.errorColor,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Access Denied',
                style: HobbiesTypography.sectionTitle.copyWith(
                  color: HobbiesTheme.textDark,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                message ??
                    'You do not have permission to view or manage this media gallery.',
                textAlign: TextAlign.center,
                style: HobbiesTypography.bodyText.copyWith(
                  color: HobbiesTheme.textSecondary,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error presentation widget with a retry callback.
class _GalleryErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const _GalleryErrorState({
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Gallery error: Unable to load media',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32.0,
            vertical: 40.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 76.0,
                height: 76.0,
                decoration: BoxDecoration(
                  color: HobbiesTheme.errorColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  size: 38.0,
                  color: HobbiesTheme.errorColor,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Unable to Load Media',
                style: HobbiesTypography.sectionTitle.copyWith(
                  color: HobbiesTheme.textDark,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                message ??
                    'An unexpected error occurred while loading your gallery media.',
                textAlign: TextAlign.center,
                style: HobbiesTypography.bodyText.copyWith(
                  color: HobbiesTheme.textSecondary,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton.icon(
                key: const Key('gallery_retry_button'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18.0),
                label: const Text('Retry Loading'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
