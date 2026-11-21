# AUTH-03B: secure authentication foundation

Decision: AND-M2-FE-AUTH-DEC-20261121-01. Owner: M2 / Vizhan.

This batch implements configuration, secure persistence, SDK bootstrap and
application session state. It provides no authentication forms, OAuth launch,
callback handling, API client, account initialization or module navigation.
Authentication alone never authorizes a module: `moduleHomeAuthorized` is always
false. The official logo and technical starter scaffold are retained.

## Public configuration contract

These are proposed build-variable names for review; no production values are
provided or embedded. The application reads Dart compile-time environment values,
not `.env` files. Public build variables can be extracted from an app binary and
must never contain secrets.

| Name | Contract |
| --- | --- |
| `ANDRIL_ENV` | `development` (default), `staging`, or `production` |
| `ANDRIL_SUPABASE_URL` | Required HTTPS hosted `*.supabase.co` project root |
| `ANDRIL_SUPABASE_PUBLIC_KEY` | Required public `sb_publishable_...` key or anon-role JWT |
| `ANDRIL_API_BASE_URL` | Required absolute HTTPS backend base URL; consumed only as validated configuration in this batch |

URLs reject user information, query strings and fragments. Supabase URLs reject
API paths. Backend path/version composition is deferred to the API-client batch.
Key-shape checking rejects secret/service-role keys; it does not cryptographically
validate a legacy anon key or prove deployment readiness. No variable or raw
exception value is rendered in errors. Missing configuration stops before secure
storage or SDK initialization and displays a minimal configuration-required state.
The backend Feature 07 verifier has its own publishable-key-only requirement;
frontend legacy-anon compatibility does not change the backend configuration.

## Composition and ownership

`main.dart` still initializes Flutter bindings and launches `AndrilApp`. The app
owns asynchronous bootstrap, loading/error presentation and controller disposal.
`SupabaseBootstrap.start` memoizes its initialization future, including failure;
concurrent calls return one controller. The production entry point also memoizes
bootstrap for the application lifetime. Tests inject an initializer/session source
and never initialize a hosted Supabase project.

Provider publishes one `SessionController` above the application. There is one
application auth-event subscription, separate from the SDK's internal persistence
subscription. SDK debug output is disabled. Do not attach sensitive SDK/network
logging listeners. A failed bootstrap requires a fresh application start rather
than repeated initialization over partial SDK state.

## Secure storage

The adapters implement the actual `LocalStorage` and `GotrueAsyncStorage`
interfaces from locked `supabase_flutter` 2.18.3 / `gotrue` 2.27.3. Both session
JSON and PKCE verifier data use `flutter_secure_storage` 11.2.0 through a mockable
key/value interface. Android uses the plugin's standard encryption options with
automatic reset-on-error disabled; biometric presence is not introduced here.

Keys are scoped by environment and Supabase project host. Session, PKCE and flow
receipt keys are distinct. Storage operations are serialized. A read/write/delete
failure is sanitized, latches the adapter closed and invalidates controller state.
There is no SharedPreferences fallback and no automatic migration from insecure
session storage. Persistence failures swallowed by SDK internals still reach the
controller through the adapter's failure stream.

A secure flow receipt binds ordinary/recovery disposition to the exact access
token. It is stored securely and never exposed by Provider. A recovery receipt
survives restart. Missing, malformed or mismatched receipts fail unavailable;
they never promote an unclassified persisted session to an ordinary login. A crash
between SDK session persistence and receipt persistence therefore favors denial.
This also means a startup token refresh that races classification can require
normal reauthentication. Later recovery/login UX must make that safe state usable.

Device encryption does not promise protection against a compromised device,
screenshots or instant server-side revocation. Android backup exclusions and
real-device Keystore/restore testing remain a platform-release dependency. Tests
exercise mocked storage and plugin interfaces, not device encryption guarantees.
If secure deletion fails, private in-memory state is still cleared, but durable
deletion cannot be guaranteed. Later logout UX must report failure accurately
and must not promise that remote sessions or persisted credentials were revoked.

## Session behavior

| State/event | Behavior |
| --- | --- |
| Initializing/restoring | No private presentation or module authorization |
| No stored session | Signed out; technical scaffold remains available |
| Valid classified ordinary session | Signed in; still no module authorization |
| Recovery event/receipt | Recovery gate; ordinary signed-in continuation suppressed |
| Sign-in | Updates identity after secure classification; startup races cannot override persisted recovery |
| Token refresh/user update | Maintains classified flow for the active identity; does not disclose tokens |
| Sign-out | Clears registered private state, removes flow receipt and resets recovery latch |
| Different user | Clears previous private state and invalidates previous work |
| Auth/storage/cleanup error | Unavailable; private state cleared; no raw error displayed |

Recovery stays latched until an explicit signed-out boundary. There is no reset UI
or logout action in this batch; later flows consume Supabase operations/events.
The SDK retains ownership of session refresh. No manual token refresh loop or
session invalidation guarantee is added. Expired or unparseable-expiry snapshots
cannot be exposed as restored signed-in state.

Controller generations change at event/error/disposal boundaries. Future private
work must capture the generation and check `isCurrent` before applying results.
Register idempotent synchronous private-state clearers and unregister them when
their owning feature is disposed. Stale work is ignored rather than presumed
cancelled at its remote source. UI state contains phase/subject only, not tokens,
provider payloads, metadata or backend authorization.

## Scope and AUTH-03C dependencies

- Approve final configuration names and nonproduction deployment values.
- Supply approved SC-01–SC-04 mapping, screen designs and copy.
- Approve callback URI/Android delivery and recovery/logout policies. Automatic
  SDK deep-link consumption is explicitly disabled until that batch.
- Choose Google browser/native flow; configure providers outside this batch.
- Add auth forms and recovery UX in their existing feature folders.
- Add backend token delivery and account/onboarding handoff only when authorized.
- Resolve Android release networking and secure-storage backup policy separately.
- Run real-device secure persistence tests and nonproduction end-to-end flows
  under separate authorization. No real credentials or hosted Auth were used here.

Dependencies and lockfile are unchanged. Tests use synthetic SDK sessions and
mocked auth/storage boundaries. The Gradle APK check encountered a local Java TLS
trust failure while downloading Gradle, before Android compilation. No certificate
validation or trust settings were weakened to bypass it.

## Local verification

- Installed validation SDK: Flutter 3.47.9 / Dart 3.13.7. Repository CI pins were
  not changed to match this local patch version.
- Locked dependency resolution: passed with `--enforce-lockfile`; no manifest or
  lockfile changes.
- `dart format`: applied to all changed Dart files.
- `flutter analyze --no-pub`: no issues.
- Final full Flutter suite: 49 passed, 0 failed, 0 skipped (43 foundation cases
  plus 6 application/widget cases).
- `flutter build bundle --debug --no-pub`: passed.
- Android APK: environment-blocked before compilation by the Gradle download
  certificate error described above; no Android build success is claimed.
- A transient null-byte integrity problem in two new files was repaired; analysis,
  the full test suite, compilation and source-integrity checks were repeated.
