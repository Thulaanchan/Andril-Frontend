# Proposed Flutter architecture

- Feature-first folders with `data`, `domain`, `presentation` placeholders.
- MVVM may be used inside `presentation` after team design review.
- `shared_core`: account-level concerns (onboarding, auth, privacy, billing).
- `features/common`: reusable **module-scoped** experiences, not shared
  identity or unscoped private storage.
- `features/learning`, `hobbies`, `social`: exactly three product modules.
- M5 Social Personality destination should be the same destination when
  reached from Social Home or Social Profile; not an onboarding step.
- Backend API contract, dependency-injection library, state-management
  package, RTC SDK, Mapbox SDK and payment SDK are **not selected/installed**
  by this scaffold.
