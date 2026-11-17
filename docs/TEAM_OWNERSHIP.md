# ANDRIL mobile feature ownership — project working map

Status: owner mappings reflect the user-supplied M5 audit and BRD baseline;
where a cross-module lead is not confirmed, do not treat a directory as
a final ownership decision.

| Member | Primary mobile boundary |
|---|---|
| M1 Thusa | `features/learning`, Diary, AI Chat integration |
| M2 Vizhan | `shared_core`, account/auth/privacy/wallet/module identity |
| M3 Priyanka | `features/hobbies`, Hobbies Map, Gallery, Flight Points, shared XP input |
| M4 Thushani | `features/common/{chat,audio_calls,video_calls,live_streaming,notifications,virtual_gifts}` and `features/social/moodtone` |
| M5 Thulaanchan | `features/social` (except MoodTone), shared Groups backend contracts and client integration |
| M6 Lucina | QA/CI and backend/Admin safety contract integration; Angular app is in a separate repository |

Shared-feature implementation requires cross-owner review; directories do
not override approved business ownership or authorization contracts.
