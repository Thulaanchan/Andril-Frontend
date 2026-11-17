# Privacy and security constraints for future implementations

1. The backend must derive account and authorized module-profile identities
   from verified authentication. Do **not** trust profile or module claims
   from the UI as the source of authority.
2. Network requests, local cache keys, storage and navigation state must
   be partitioned by the active, authorized module profile. Clear private
   state when account/module access changes.
3. Social is 18+ and explicitly opted in; a one-sided like must never
   authorize match-gated messaging or calls.
4. MoodTone must never appear or be submitted in Learning/Hobbies.
5. Keep provider secrets and privileged tokens out of the mobile binary.
6. Payment, virtual gift, XP and Flight Points balances are server-authoritative
   and must use verified, idempotent backend ledgers.
7. Use the actual versioned backend OpenAPI spec for API contract integration.
   The M5 audit reports private Social profile authorization as missing;
   show a denial/unavailable state until M2's contract is implemented.
8. Placeholder directories are **not** authorization enforcement.
