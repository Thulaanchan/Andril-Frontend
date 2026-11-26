import 'package:flutter/material.dart';

/// Presentation component for managing the user's private Social profile photo.
///
/// Follows M5 Media & Privacy Governance:
/// - Connects strictly to M2-owned private media selection and contracts.
/// - Does not implement independent upload servers or public bucket storage.
/// - Supports preview, replace, remove, and loading/unavailable presentation states.
class SocialProfilePhotoSection extends StatelessWidget {
  final String? photoPath;
  final String? networkPhotoUrl;
  final bool isLoading;
  final VoidCallback? onSelectPhoto;
  final VoidCallback? onRemovePhoto;

  const SocialProfilePhotoSection({
    super.key,
    this.photoPath,
    this.networkPhotoUrl,
    this.isLoading = false,
    this.onSelectPhoto,
    this.onRemovePhoto,
  });

  bool get hasPhoto => (photoPath != null && photoPath!.isNotEmpty) || (networkPhotoUrl != null && networkPhotoUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage: networkPhotoUrl != null ? NetworkImage(networkPhotoUrl!) : null,
              child: (!hasPhoto && !isLoading)
                  ? Icon(Icons.person, size: 56, color: theme.colorScheme.onSurfaceVariant)
                  : null,
            ),
            if (isLoading)
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(128),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: theme.colorScheme.primary,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  key: const Key('change_photo_button'),
                  customBorder: const CircleBorder(),
                  onTap: isLoading ? null : onSelectPhoto,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              key: const Key('upload_photo_button'),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(hasPhoto ? 'Change Photo' : 'Add Photo'),
              onPressed: isLoading ? null : onSelectPhoto,
            ),
            if (hasPhoto && onRemovePhoto != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                key: const Key('remove_photo_button'),
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                label: const Text('Remove', style: TextStyle(color: Colors.red)),
                onPressed: isLoading ? null : onRemovePhoto,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
