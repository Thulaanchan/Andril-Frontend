import 'package:flutter/material.dart';

import '../../../presentation/screens/hobbies_gallery_screen.dart';
import '../viewmodels/hobbies_gallery_viewmodel.dart';

/// Reactive presentation binding connecting [HobbiesGalleryScreen] to [HobbiesGalleryViewModel].
///
/// Implements checkpoint M3-CP-02C-06 under HOB-01 (Hobbies Photo Gallery and Media Management).
///
/// Architectural & Privacy Guarantees:
/// - Clean Architecture MVVM: Observes [HobbiesGalleryViewModel] reactively via [ListenableBuilder]
///   and projects deterministic presentation state down to [HobbiesGalleryScreen].
/// - Fail-Closed Privacy: Immediately removes private media widgets when the ViewModel signals
///   authoritative access denial ([HobbiesGalleryStatus.denied]).
/// - Lifecycle Safety: Triggers initial retrieval once upon mount (if [autoLoad] is true)
///   without triggering duplicate requests on subsequent widget rebuilds.
/// - External Ownership: Does not dispose an externally injected [HobbiesGalleryViewModel].
/// - Diagnostic Redaction: Displays only safe user-facing error messages, never leaking
///   private URLs, tokens, or raw exception strings into the UI.
class HobbiesGalleryBinding extends StatefulWidget {
  /// The reactive ViewModel managing gallery presentation state.
  final HobbiesGalleryViewModel viewModel;

  /// Whether to automatically trigger [viewModel.load()] on initial widget mount.
  final bool autoLoad;

  /// Optional custom title for the gallery app bar.
  final String? title;

  /// Optional custom subtitle displayed beneath the header.
  final String? subtitle;

  /// Whether the upload action is enabled.
  final bool isUploadEnabled;

  /// Callback invoked when the user taps the upload button.
  final VoidCallback? onUploadPressed;

  /// Callback invoked when the user taps a media card.
  final void Function(HobbiesGalleryItem item)? onItemTapped;

  /// Creates a [HobbiesGalleryBinding].
  const HobbiesGalleryBinding({
    super.key,
    required this.viewModel,
    this.autoLoad = true,
    this.title,
    this.subtitle,
    this.isUploadEnabled = false,
    this.onUploadPressed,
    this.onItemTapped,
  });

  @override
  State<HobbiesGalleryBinding> createState() => _HobbiesGalleryBindingState();
}

class _HobbiesGalleryBindingState extends State<HobbiesGalleryBinding> {
  @override
  void initState() {
    super.initState();
    if (widget.autoLoad && !widget.viewModel.isRevoked) {
      widget.viewModel.load();
    }
  }

  @override
  void didUpdateWidget(covariant HobbiesGalleryBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel &&
        widget.autoLoad &&
        !widget.viewModel.isRevoked) {
      widget.viewModel.load();
    }
  }

  @override
  void dispose() {
    // Note: widget.viewModel is externally injected and owned by the caller/DI root.
    // It must NOT be disposed here.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (BuildContext context, Widget? child) {
        return HobbiesGalleryScreen(
          title: widget.title ?? HobbiesGalleryScreen.defaultTitle,
          subtitle: widget.subtitle ?? HobbiesGalleryScreen.defaultSubtitle,
          status: widget.viewModel.status,
          items: widget.viewModel.items,
          errorMessage: widget.viewModel.errorMessage,
          onRetry:
              widget.viewModel.isRevoked ? null : () => widget.viewModel.load(),
          isUploadEnabled: widget.isUploadEnabled,
          onUploadPressed: widget.onUploadPressed,
          onItemTapped: widget.onItemTapped,
        );
      },
    );
  }
}
