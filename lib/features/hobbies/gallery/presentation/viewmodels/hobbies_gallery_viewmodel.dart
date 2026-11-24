import 'package:flutter/foundation.dart';
import 'package:andril_mobile/features/hobbies/presentation/screens/hobbies_gallery_screen.dart';
import '../../domain/entities/hobbies_media.dart';
import '../../domain/usecases/get_hobbies_gallery_media_usecase.dart';

/// Authoritative exception signaling access denial to the Hobbies Gallery.
///
/// Thrown only by explicit authorization checks or session evaluators,
/// never inferred from arbitrary exception message strings.
class HobbiesGalleryAccessDeniedException implements Exception {
  final String message;
  const HobbiesGalleryAccessDeniedException([
    this.message = 'Access to Hobbies Gallery was denied.',
  ]);

  @override
  String toString() => 'HobbiesGalleryAccessDeniedException: $message';
}

/// ViewModel coordinating state management and presentation mapping for Hobbies Gallery.
///
/// Implements [ChangeNotifier] to expose deterministic gallery states to the UI layer
/// under HOB-01 (Hobbies Photo Gallery and Media Management).
///
/// Architectural & Privacy Boundaries:
/// - Presentation Scoping: Manages offline presentation state transitions only. Does not
///   authenticate, authorize, or store credentials locally.
/// - Privacy Protection: Never exposes retained media items when in [HobbiesGalleryStatus.loading],
///   [HobbiesGalleryStatus.denied], or [HobbiesGalleryStatus.error] states.
/// - Fail-Closed Revocation: Once an authoritative denial signal is received, the ViewModel
///   fails closed, clears all private media, and blocks further [load] attempts.
/// - Defending Collections: Exposes media items through unmodifiable views to prevent external mutation.
/// - Race Condition Protection: Uses request tracking to prevent out-of-order asynchronous
///   completions from overwriting newer state or restoring revoked media.
/// - Module Isolation: Segregates Hobbies media from Learning and Dating profiles.
/// - Excluded Features: Excludes HOB-03 Andril Map contributions and retired Photo Portfolios.
class HobbiesGalleryViewModel extends ChangeNotifier {
  final GetHobbiesGalleryMediaUseCase _getGalleryMediaUseCase;

  int _activeRequestId = 0;
  HobbiesGalleryStatus _status = HobbiesGalleryStatus.loading;
  List<HobbiesGalleryItem> _items = const [];
  bool _isRevoked = false;
  bool _isDisposed = false;

  /// Creates a [HobbiesGalleryViewModel] with injected [getGalleryMediaUseCase].
  HobbiesGalleryViewModel(this._getGalleryMediaUseCase);

  /// Exposes the injected use case for testing and architectural inspection.
  GetHobbiesGalleryMediaUseCase get getGalleryMediaUseCase =>
      _getGalleryMediaUseCase;

  /// Current presentation status of the gallery.
  HobbiesGalleryStatus get status => _status;

  /// Current media items presented in the gallery.
  ///
  /// Defensively returns an empty unmodifiable list when the gallery is in a non-populated state
  /// to prevent retained media exposure during loading, error, or denied access.
  List<HobbiesGalleryItem> get items {
    if (_status != HobbiesGalleryStatus.populated) {
      return const <HobbiesGalleryItem>[];
    }
    return List.unmodifiable(_items);
  }

  /// Whether an asynchronous media load operation is currently in progress.
  bool get isLoading => _status == HobbiesGalleryStatus.loading;

  /// Whether this ViewModel has received an authoritative access denial signal.
  bool get isRevoked => _isRevoked;

  /// Whether this ViewModel has been disposed.
  bool get isDisposed => _isDisposed;

  /// User-facing generic error message when in [HobbiesGalleryStatus.error].
  ///
  /// Strictly avoids leaking raw exception details, URLs, or private IDs.
  String? get errorMessage => _status == HobbiesGalleryStatus.error
      ? 'Unable to load gallery media. Please try again.'
      : null;

  /// Asynchronously loads private gallery media for the active Hobbies context.
  ///
  /// Guarantees:
  /// - Sets [HobbiesGalleryStatus.loading] before retrieval.
  /// - Maps domain [HobbiesMedia] entities to presentation [HobbiesGalleryItem] models.
  /// - Sets [HobbiesGalleryStatus.empty] when zero items are retrieved.
  /// - Sets [HobbiesGalleryStatus.populated] when one or more items are retrieved.
  /// - Sets [HobbiesGalleryStatus.error] on recoverable failures.
  /// - Ignores out-of-order responses if a newer request has started.
  /// - Blocks execution if access has been revoked.
  Future<void> load() async {
    if (_isDisposed || _isRevoked) {
      return;
    }

    final int requestId = ++_activeRequestId;

    if (_status != HobbiesGalleryStatus.loading) {
      _status = HobbiesGalleryStatus.loading;
      _items = const [];
      _notifySafely();
    }

    try {
      final List<HobbiesMedia> mediaList = await _getGalleryMediaUseCase();

      if (_isDisposed || _isRevoked || requestId != _activeRequestId) {
        return;
      }

      final List<HobbiesGalleryItem> mappedItems = mediaList
          .map((HobbiesMedia m) => HobbiesGalleryItem(
                id: m.id,
                title: m.title,
                caption: m.caption,
                mediaUrl: m.mediaUrl,
                hobbyTag: m.hobbyTag,
                createdAt: m.createdAt,
              ))
          .toList(growable: false);

      _items = mappedItems;
      _status = mappedItems.isEmpty
          ? HobbiesGalleryStatus.empty
          : HobbiesGalleryStatus.populated;
      _notifySafely();
    } catch (e) {
      if (_isDisposed || _isRevoked || requestId != _activeRequestId) {
        return;
      }

      _items = const [];
      if (e is HobbiesGalleryAccessDeniedException) {
        _isRevoked = true;
        _status = HobbiesGalleryStatus.denied;
      } else {
        _status = HobbiesGalleryStatus.error;
      }
      _notifySafely();
    }
  }

  /// Explicitly processes an authoritative access-denied signal.
  ///
  /// Clears retained media, marks the ViewModel as revoked, transitions to
  /// [HobbiesGalleryStatus.denied], and prevents any future [load] operations.
  void handleAccessDenied() {
    if (_isDisposed) return;
    _isRevoked = true;
    _items = const [];
    if (_status != HobbiesGalleryStatus.denied) {
      _status = HobbiesGalleryStatus.denied;
      _notifySafely();
    }
  }

  void _notifySafely() {
    if (!_isDisposed && hasListeners) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
