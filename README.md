# ANDRIL Flutter Mobile — structure scaffold

**Status: PROPOSED PROJECT STRUCTURE / NOT AN IMPLEMENTED PRODUCT.**

This workspace is an independent Flutter **Android** project layout. It follows
ANDRIL BRD **v2.4-R1 (11 November 2026; review draft)** and the
user-supplied **M5 audit (16 November 2026, Member-5 at 66d40f0)**,
plus the subsequently proposed Flutter directory tree.

## Product scope and rules

- Exactly three product modules: **Learning**, **Hobbies**, **Social**.
- `app`, `core`, `shared_core`, and `features/common` are **technical**
  organizational areas, **not additional product modules**.
- One account, separate private, scoped module identities; no cross-module
  identity, data, photos, connection, matching or XP leakage.
- Social is **18+ and opt-in**. Match-based private messaging needs a valid
  mutual match and current server authorization.
- MoodTone is **Social-only**, even though ordinary chat is common.
- Hobbies Andril Map uses **Mapbox** (SDK integration not included);
  photo submissions need server-side review and approval before public
  display or Flight Points grant.
- Questionnaire `v1`: 12 required questions for completion; optional
  participation; it is **not** an onboarding completion requirement.
- No removed Hobbies event-creation/discovery/participation or removed
  Learning quizzes, missions, or focus features are scaffolded.

## Setup on a development PC

All six developers use Flutter 3.47.5 stable and its bundled Dart 3.13.4.
Use the existing workspace root and keep `pubspec.lock` with the project.

| Component | Version or setting |
| --- | --- |
| Flutter and Dart | Flutter 3.47.5 stable, Dart 3.13.4 |
| Android Studio | 2026.1.4 |
| Local JDK | Android Studio bundled OpenJDK 25.0.3 |
| CI JDK | Eclipse Temurin 25.0.3 |
| Android SDK levels | Compile 36, target 36, minimum 24 |
| Android SDK tools | Build Tools 36.0.0, Platform Tools 37.0.1, Command-line Tools 23.0 |
| Native tools | NDK 28.2.13676358, CMake 3.22.1 |
| Gradle and AGP | Gradle wrapper 9.3.1, Android Gradle Plugin 9.1.0 |
| Kotlin | Flutter template setting 2.4.0, Kotlin Android activity |
| Android identity | Local development application ID and namespace `com.andril.mobile` |
| Emulator | Pixel 7 Pro, Android 16 API 36.1, x86_64 |
| Git for Windows | 2.51.0.windows.2 |

On the audited Windows machine, Flutter is at `C:\src\flutter` and the
Android SDK is at `C:\Android\Sdk`. Set your own local SDK paths through
the normal Flutter and Android tooling. Review Android SDK license terms
interactively if `flutter doctor -v` reports a pending license.

From the project root, run the Windows setup script in PowerShell:

```powershell
.\scripts\setup_android.ps1
```

Or execute the commands individually:

```powershell
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug --no-pub
flutter emulators
flutter devices
```

The debug APK output path is `build/app/outputs/flutter-apk/app-debug.apk`.
Select the existing Android emulator in `flutter run -d <device-id>`.
Android launcher resources provide `ANDRIL` and `அன்றில்`. English Dart ARB resources
are included. Approved Tamil and Sinhala translations are pending.

The Android application ID is approved for local development. Play Console
registration and release signing require a separate release setup. Keep
provider credentials, SDK paths, and signing material out of the repository.

## Status of included content

- `lib/main.dart`, `lib/app/*`: **basic local starter shell only**.
- `assets/branding/andril_black_logo.png`: available project logo asset.
- Feature folders: **empty `.gitkeep` placeholders**, not developed UI.
- `test/app/andril_app_test.dart`: starter widget smoke test for the three product module labels.
- `integration_test`: placeholders; no integration tests yet.
- `l10n`: English ARB starter only; other languages and translation policy
  require approved implementation decisions.
- `docs`: guidance and responsibility mapping, not approved API contracts.
- `android`: Android platform project generated from the pinned Flutter SDK.
- Existing backend API/auth/persistence implementations are not copied into
  the Flutter app. Do not treat M2's account-level starter opt-in as proof
  of authorized private profile access; that contract remains a blocker in
  the supplied M5 audit.

## Integration and repositories

The app is intended for its own repository `andril-mobile`, separate from
the `Andril-Backend` ASP.NET Core server and `andril-admin` Angular UI.
Validate request paths, DTOs and authorization against the actual versioned
backend OpenAPI contract; no endpoints are assumed in this scaffold.

See `docs/FOLDER_STRUCTURE.txt`, `docs/TEAM_OWNERSHIP.md`, and
`docs/SECURITY_BOUNDARIES.md`.
