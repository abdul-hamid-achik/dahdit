# Dahdit Roadmap

Last updated: 2026-05-14

This roadmap turns the technical spec into an execution plan for getting Dahdit from the current scaffold to a working MVP. The priority is a real vertical slice first: seeded lesson content, API auth/progress, iOS lesson playback, local persistence, and repeatable verification.

## Current State

The repository already has the foundation in place:

- Monorepo with `Taskfile.yml`, Bun workspaces, Docker Compose, CI, and shared TypeScript config.
- `packages/morse-core` with Morse encode/decode, exercise payload validation, send timing rules, SRS scheduling, and parity vectors.
- `services/api` with Hono, Yoga, Pothos, Drizzle schema, auth scaffold, lesson mutations, grading, XP, streaks, SRS scheduling, migrations, and seed data.
- `apps/ios` with an Xcode project, SwiftUI shell, local SPM packages, Swift parity tests, audio/haptics package, Keychain token store, and privacy manifest.
- `apps/web` with a Nuxt companion page, interactive Morse preview, API-backed learner dashboard, and Cloudflare/Void deployment shape.
- Docs in `docs/` for ADRs, runbook, and content authoring.

Verified commands in the current environment:

```bash
task codegen
task check
task test
task build
task smoke
task uitest
```

`task setup` was previously verified with Docker/Xcode in a healthier local state. iOS 26.5 simulator/device support is now available again locally.

Recent progress:

- Fixed local Postgres by adding a repo-owned `infra/postgres` image with `pg_cron` installed and Compose startup flags for `shared_preload_libraries`.
- Added Drizzle migration metadata so the existing SQL migrations apply through `task migrate` and future migrations can be generated normally.
- Fixed the API Docker build workspace manifest set so `docker compose build api` succeeds with the root Bun workspace.
- Made `task setup` use Bun directly and pinned `packageManager` to `bun@1.3.11` because the pinned Vite+ alpha does not support Bun as an installer.
- Added `task smoke`.
- Added `services/api/scripts/smoke.ts` to exercise health, readiness, signup, login, refresh-token rotation/reuse rejection, skill tree, lesson start, lesson completion, and leaderboard through HTTP/GraphQL.
- Added refresh-token family reuse detection in the API.
- Added authenticated `dueReviews` GraphQL coverage for SRS review queues.
- Replaced the iOS mock auth/home/lesson path with real API calls.
- Added Swift Codable mirrors for server exercise payloads, including default decoding for omitted `toneHz`.
- Added iOS GraphQL decoding diagnostics so nullable GraphQL error responses surface useful messages instead of generic decode failures.
- Added a debug-only token-store fallback for unsigned simulator builds while keeping Keychain as the primary storage path.
- Verified the iOS Debug simulator build, install, and launch on iPhone 17 / iOS 26.4. The simulator smoke reached signup, authenticated home, the seeded skill tree, the first lesson, `matchCharacterToCode`, and `listenAndType` against the local API.
- Wired `MorseAudioPlayer` into the iOS lesson flow for `listenAndType` and `copyAtSpeed`, including prompt playback state and playback error display.
- Added manual send controls for `tapTheCode` and `translateToMorse` so users are not blocked by gesture-only input. The send views now include dit, dah, clear/delete, character gap, and word gap controls where appropriate.
- Re-verified the iOS Debug simulator build after the audio/send-control changes.
- Reworked the iOS first-run, home, lesson shell, and exercise screens toward a Morse-game UX: dark radio-station background, signal meter, HUD chips, stronger lesson cards, station-style exercise panels, and paddle-like send controls.
- Added a reusable `ExerciseCard` component and button/text-field styles for lesson exercises.
- Normalized the remaining iOS screens with shared radio-game chrome: Practice, Leagues, Profile, root loading, and home/lesson error states now use the same background, headers, panels, chips, and empty-state treatment.
- Removed remaining stock `List`, `Form`, `ContentUnavailableView`, and `navigationTitle` styling from app screens.
- Added API-backed data to Practice, Leagues, Profile, and the Home HUD. Practice now reads `dueReviews`, Leagues reads `leaderboard`, Profile reads `me.stats`, and Home shows real XP/streak.
- Added `completeReviews` to the API so due SRS cards can be graded and rescheduled from the client.
- Replaced the Practice queue placeholder with a playable SRS review loop: Morse audio prompt, typed copy answer, reveal/check state, grade picker, and API-backed save.
- Extended `task smoke` to seed a due review card and verify `dueReviews` plus `completeReviews` end to end.
- Installed Apollo iOS 2.1.1 through SPM, made `task swiftgen` install/use the bundled CLI, and generated Swift operation models into `DahditGraphQL`.
- Replaced the temporary iOS raw-query wrapper with ApolloClient + generated operations while keeping the same app-facing `DahditAPI` surface.
- Added an Apollo custom `JSON` scalar adapter so generated operations can carry exercise payload objects and answer logs safely.
- Added startup session validation on iOS: stored access tokens are checked with `me`, expired access tokens rotate through `refreshToken`, and stale invalid sessions are cleared back to onboarding.
- Wired Profile sign-out and confirmed account deletion UI to real token clearing / `deleteAccount` behavior.
- Extended the GraphQL `User` type with `stats` and made API context ignore soft-deleted users immediately.
- Updated `task ios` and `task app` to run XcodeGen before opening/building so newly added Swift files are included in `Dahdit.xcodeproj`.
- Updated the runbook with local stack smoke instructions.
- Added Apollo per-request auth retry on iOS: auth failures normalize through `DahditAPI`, `TokenRefreshCoordinator` serializes refresh attempts, and failed operations retry once after token rotation.
- Added a generated `DahditUITests` target, `task uitest`, and an automated iPhone 17 / iOS 26.5 signup smoke that resets auth, signs up through the UI, dismisses the system password sheet, and verifies the seeded home screen.
- Made onboarding disable password autofill only under `--ui-testing` so UI tests do not get intercepted by the iOS password assistant while normal app UX keeps password content types.
- Fixed iOS lesson navigation so lesson cards open the real lesson flow through the parent `NavigationLink`.
- Fixed Apollo custom `JSON` scalar decoding and fractional timestamp parsing for generated iOS operations.
- Added `DahditGraphQL` package tests for all five seeded exercise payload kinds and included them in `task test`.
- Expanded `task uitest` into a full seeded lesson smoke: signup, home, first lesson, all five exercise kinds, `completeLesson`, and completion screen on iPhone 17 / iOS 26.5.
- Stabilized `task smoke` review seeding so `dueReviews` is not sensitive to UTC vs user-timezone date boundaries.
- Added a dev-only `/__test/seed-review` API helper for simulator automation. It is disabled in production and lets UI tests seed a due SRS card for the signed-up local user.
- Added stable Practice accessibility identifiers and expanded `task uitest` again to cover the Practice SRS flow: seed due card, open Practice, play the short review signal, copy `E`, grade it, save with `completeReviews`, and verify the saved state.
- Added a `DahditGraphQL` package-level forced auth retry test that simulates an expired access token, runs the one-shot refresh handler, retries `me`, and verifies the second request uses the refreshed bearer token.
- Added first-pass SwiftData lesson attempt drafts: the app persists lesson answer logs, deletes the draft after successful `completeLesson`, and marks failed completions for later sync.
- Added pending lesson completion retry on lesson start and app foregrounding, plus a "Saved for sync" state when completion cannot reach the API.
- Stabilized lesson row hit testing by making `LessonBubble` a full-width single accessibility element with an explicit content shape.
- Added persisted SwiftData audio/profile settings for WPM, Farnsworth WPM, tone Hz, and haptics on/off; lesson playback now applies the selected tone and Practice playback uses the selected timing.
- Wired first-pass send haptics for lesson `tapTheCode` and `translateToMorse` manual/gesture key input, gated by the persisted haptics setting.
- Stabilized the iOS UI smoke against delayed system password-save prompts and the home lesson card hit-testing quirk; the full `task uitest` suite is green again on iPhone 17 / iOS 26.5.
- Expanded seed content into one complete beginner `Foundations` skill with four lessons and 20 exercises. The curriculum now lives in `services/api/scripts/curriculum.ts`, seed uses idempotent upserts, and API tests validate payloads/generated Morse solutions.
- Updated GitHub Actions checkout usage to `actions/checkout@v6` so CI opts into the Node 24 action runtime instead of relying on the deprecated Node 20 path.
- Decided the web companion stays in MVP as a lightweight learner station, not a second lesson platform. The Nuxt page now has email/password signup/login, token refresh, real API-backed stats, skill tree, due reviews, and leaderboard data, styled to match the iOS dark radio-game chrome.
- Expanded local CORS defaults and Compose config to allow both `localhost` and `127.0.0.1` web dev origins, with `POSTGRES_PORT` configurable for machines where host port `5432` is already occupied.

Known setup gaps:

- Docker Desktop must be running for full local Postgres/API Compose workflow.
- `task swiftgen` now installs Apollo's bundled CLI on first run and generates Swift operation models. The CLI binary is ignored locally because it is reproducible from SPM.
- iOS API calls now use Apollo-generated operations with startup session validation and one-shot per-request auth refresh/retry. The forced expired-access-token retry path is covered by a `DahditGraphQL` package test.
- The unsigned simulator build uses a `DEBUG` UserDefaults fallback if Keychain writes fail. Signed simulator/device/TestFlight builds still need a real Keychain verification pass.
- All five lesson exercise kinds are covered by `task uitest`, and Practice now has a short simulator audio/playback smoke. Deeper audio quality and haptics still need simulator/device verification.
- Practice, leaderboard, profile, and Home HUD are API-backed. Practice has a first playable SRS review loop; richer review variants, replay telemetry, and Practice haptic feedback still need to be added. Profile audio settings are persisted and wired into playback.
- Offline `completeLesson` retry is implemented through SwiftData pending drafts and app-start/foreground sync. It still needs a manual network-disconnect simulator smoke before being treated as fully verified.
- iOS 26.5 simulator/device support is installed and `task app` builds again.
- The web scripts use Nuxt/Vitest directly. Vite+ remains pinned, but direct `vp build` is not the stable Nuxt path right now.

## MVP Completion Status

Current status: Dahdit has a working local vertical slice, but it is not a complete MVP yet. The core iOS lesson loop, API auth/progress path, Practice review loop, local smoke tests, simulator UI smoke, and CI are working. The remaining work is mostly product completeness, offline validation, device QA, content depth, and release readiness.

| Area | Status | What is missing |
| --- | --- | --- |
| Local dev + CI | Mostly done | CI is green and uses the Node 24-compatible checkout action; keep dependency/runtime pins current. |
| Backend vertical slice | Mostly done | Add typed GraphQL error unions, production rate limiting/CORS, broader anti-cheat and SRS edge-case tests. |
| iOS auth + lesson loop | Mostly done | Verify signed Keychain behavior on simulator/device, add replay telemetry, and polish error states. |
| Offline lesson progress | Partial | Run the manual network-off/network-on simulator smoke, add skill/lesson content cache, and add mid-lesson resume UI. |
| Audio + haptics | Partial | Device/simulator audio quality QA, haptic feedback for wrong-answer/Practice states, replay telemetry, and golden audio tests. |
| Curriculum content | Mostly done | One complete beginner skill is seeded and repeatably validated; still needs manual playthrough beyond the first lesson and more authored content before launch. |
| Practice/SRS | Partial | Add richer review variants, replay tracking, haptics, and overdue-card UX for larger queues. |
| Web companion | Mostly done | Web auth and real dashboard data are wired; still needs responsive/accessibility QA and a production cookie/session hardening pass before launch. |
| TestFlight readiness | Not done | Signing, Fastlane beta lane, real device archive validation, App Store privacy checks, app icon/assets, and screenshots. |
| Staging/prod ops | Not done | VPS/staging deploy, production env/secrets, backups, metrics/logging/tracing, runbook drills, and rollback workflow. |

MVP blockers before calling this shippable:

- Manual offline completion smoke: start a lesson online, turn network off, finish, see "Saved for sync", relaunch, restore network, confirm progress syncs once.
- Audio/haptics pass on at least one real device or current simulator runtime.
- Internal TestFlight build produced and installed.
- Staging API/web environment deployed with non-local secrets.

## Command Surface

Use the single-word Taskfile commands for daily work:

```bash
task setup       # Bun install, start postgres, migrate, seed
task dev         # docker compose + codegen + web dev server
task ios         # generate iOS code if available, then open Xcode
task codegen     # schema + TS types + iOS operations
task check       # web and API type checks
task test        # TS/Bun tests + Swift core/GraphQL tests
task build       # web + iOS unsigned build
task site        # web build only
task app         # iOS build only
task uitest      # iOS signup, lesson, and Practice UI smoke on simulator
task migration   # generate Drizzle migration
task migrate     # apply migrations
task seed        # seed curriculum
task smoke       # run local API smoke test
task deploy      # web deploy
```

Compatibility aliases still exist for older names such as `task build:web`, `task build:ios`, and `task db:migrate`.

## Local Environment Needed

Required:

- Bun 1.3+
- Task 3.50+
- Docker Desktop or another Docker runtime with Compose
- Xcode 26+
- XcodeGen 2.45+
- Swift 6+
- Postgres runs through Compose for local dev

Needed soon:

- Apple Developer account/team ID for device builds and TestFlight
- Wrangler or Void CLI credentials for Cloudflare/Void deploys
- A real `DATABASE_URL` for staging/prod
- A strong `JWT_SECRET` outside local dev

Optional but useful:

- `jq` for API smoke scripts
- `psql` for local DB inspection
- Figma/browser tooling for visual QA

## Definition of Working

The MVP is "working" when a fresh machine can run:

```bash
cp .env.example .env
task setup
task dev
task ios
```

And then:

- API `/health` and `/ready` pass.
- A user can sign up or log in.
- `task uitest` can sign up through the iOS UI, open the seeded lesson, complete all five exercise kinds, and render the completion screen.
- `task uitest` can seed and complete one due Practice SRS review card.
- The iOS app can fetch the real skill tree from the API.
- A seeded lesson can be started from iOS.
- All five seeded exercise kinds work end to end through the automated UI smoke.
- Completing the lesson writes a `lesson_attempts` row, XP, streak, hearts, and SRS cards.
- The iOS app survives an offline lesson completion and syncs later.
- The web dashboard can show real XP/streak/leaderboard data.
- `task check`, `task test`, `task build`, and CI pass.

## Phase 1: Local Stack Hardening

Goal: make local dev boring and repeatable.

Work:

- Verify Docker Compose end to end: Postgres, API, migrations, seed data. Done.
- Fix any Dockerfile/workspace path issues found by `docker compose build api`. Done.
- Add `task smoke` for local health checks. Done.
- Add a simple GraphQL smoke script for signup, login, `skillTree`, `startLesson`, and `completeLesson`. Done.
- Make `task setup` idempotent. Done.
- Add `.env` validation notes for local, staging, and prod. Done.

Acceptance:

```bash
task setup
docker compose up -d api
curl -fsS http://localhost:4000/health
curl -fsS http://localhost:4000/ready
task smoke
```

Verified on 2026-05-12 with Docker Desktop running.

## Phase 2: Backend Vertical Slice

Goal: make the API authoritative for auth, curriculum, progress, and lesson completion.

Work:

- Finish GraphQL auth flows: signup, login, refresh, logout, delete account.
- Add refresh-token family reuse detection. Done.
- Replace generic `Error` throws in resolvers with typed GraphQL error unions where useful.
- Finish unlock computation in `completeLesson`.
- Persist and return hearts refill state.
- Add due review query for SRS. Done.
- Add complete review mutation for SRS card rescheduling. Done.
- Add leaderboard query backed by real user stats. Done.
- Add rate limiting and CORS production origins.
- Add more domain tests for grading edge cases and SRS scheduling.

Acceptance:

```bash
task test
task check
task smoke
```

Required API behavior:

- Duplicate `completeLesson` is rejected.
- Impossibly fast attempts are rejected or XP-capped.
- Wrong answers reduce hearts.
- Perfect lesson updates unlocks.
- SRS cards are created for encountered characters/words.

## Phase 3: iOS GraphQL Integration

Goal: replace mocked iOS data with real API calls.

Work:

- Install Apollo iOS CLI setup. Done; `task swiftgen` installs Apollo's bundled CLI on first run.
- Add Apollo iOS dependency and generated operation module. Done.
- Wire `DahditAPI` to generated operations instead of the temporary manual wrapper. Done.
- Implement token refresh around Keychain storage. Done for startup validation and one-shot per-request retry through `TokenRefreshCoordinator`; forced expired-access-token retry is covered by `DahditGraphQL` tests.
- Build login/signup screens and root auth routing. Done.
- Replace `SkillTreeViewModel` mock data with `skillTree`. Done.
- Replace local lesson fixture with `startLesson`. Done.
- Send real `completeLesson` logs to the API. Done and verified by the full seeded lesson `task uitest`.
- Replace placeholder Home/Practice/Leagues/Profile read paths with real API calls. Done for `me.stats`, `dueReviews`, and `leaderboard`.
- Add a playable Practice review session backed by `dueReviews` and `completeReviews`. Done.
- Add simulator UI coverage for the Practice review session. Done.
- Store in-flight lesson attempts in SwiftData for crash/offline resume. Done for answer-log persistence and failed `completeLesson` retry; full mid-lesson resume UI still pending.

Acceptance:

```bash
task codegen
task app
task uitest
```

Simulator smoke:

```bash
open -a Simulator
xcrun simctl boot "iPhone 16" || true
xcodebuild -scheme Dahdit-Dev \
  -project apps/ios/Dahdit.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

After the app is running, use Computer Use or manual simulator inspection to verify:

- Signup through the UI reaches authenticated home with real seeded content. Verified by `task uitest` on iPhone 17 / iOS 26.5.
- Login screen renders. Verified manually on iPhone 17 simulator.
- Skill tree renders real seeded content. Verified manually and by `task uitest` on iPhone 17 simulator.
- Tapping the first lesson opens exercise flow. Verified by `task uitest`.
- Submitting answers progresses all five exercise kinds. Verified by `task uitest`.
- Audio play controls are wired for `listenAndType` and `copyAtSpeed`; Practice has a short audio-play UI smoke, while deeper lesson audio quality still needs simulator/device verification.
- Manual send controls are available for `tapTheCode` and `translateToMorse`; all seeded send exercises are covered by `task uitest`.
- Profile audio settings persist in SwiftData and are applied to playback: lesson audio uses the selected tone, Practice uses selected WPM/Farnsworth/tone, and send haptics honor the persisted haptics toggle.
- Completion screen shows server-returned XP/streak. Verified by `task uitest`.
- Practice SRS review loads a seeded due card, plays the short signal prompt, grades copy, saves through `completeReviews`, and shows the saved state. Verified by `task uitest`.

## Phase 4: Audio, Haptics, and Exercise UX

Goal: make the learning loop feel like a Morse trainer, not a form demo.

Work:

- Connect `MorseAudioPlayer` to `listenAndType` and `copyAtSpeed`. Done in code; runtime audio smoke still pending.
- Add replay tracking to exercise logs.
- Add haptic feedback for key taps and wrong answers. Key-tap haptics are wired for lesson send controls; wrong-answer haptics still pending.
- Add replay tracking and haptic feedback to the Practice SRS flow.
- Implement send pause detection in the lesson view model.
- Build polished exercise views for all five payload kinds. First pass done with station-style cards, stronger controls, and shared lesson chrome.
- Normalize app-wide screen chrome for Practice, Leagues, Profile, loading, and error states. Done.
- Add accessible manual "Done" and "Next character" alternatives. Done for send exercises through explicit symbol/gap controls.
- Add audio settings: WPM, Farnsworth WPM, tone Hz, haptics on/off. Done with SwiftData persistence and playback integration.
- Add golden audio tests for SOS at 20 WPM.

Acceptance:

- Audio has no obvious clicks at normal WPM.
- Tap thresholds behave correctly at 15 WPM and 20 WPM.
- `tapTheCode` auto-submits single-character exercises.
- `translateToMorse` supports manual Done.
- VoiceOver can operate each exercise without gesture-only blockers.

## Phase 5: Offline-First Progress

Goal: lessons remain usable with intermittent network.

Work:

- Cache skill tree and lesson content.
- Pre-fetch next unlocked lessons.
- Persist attempt drafts in SwiftData. Done for lesson answer logs.
- Queue failed `completeLesson` mutations. Done for pending completion drafts.
- Add sync state UI. Done with the lesson "Saved for sync" state.
- Retry pending completion drafts on app start/foreground and before a new lesson starts. Done.
- Resolve server/client progress conflicts by accepting server authority.

Acceptance:

- Start a lesson online, disable network, finish it, relaunch app, re-enable network, and observe progress sync.
- Duplicate queued submissions do not double-award XP.
- User sees clear syncing state without blocking local progress.

Implementation status: first-pass code exists and `task app`/`task uitest` pass, but the manual network-off/network-on simulator smoke is still pending.

## Phase 6: Web Companion

Goal: make the web app useful beyond marketing.

Work:

- Add login/signup on web.
- Add GraphQL client wrapper with auth token handling.
- Replace static dashboard data with real `me`, stats, leaderboard, and due-review data. Done for the lightweight web learner station.
- Keep the Morse preview as a public interactive demo.
- Add a web-only trial `listenAndType` exercise if it helps onboarding.
- Add responsive and accessibility QA.

Acceptance:

```bash
task site
cd apps/web && bun test
```

User-facing checks:

- Public landing page renders without auth.
- Dashboard requires auth.
- Dashboard shows real XP, streak, hearts, and leaderboard.
- Morse preview remains interactive on mobile widths.

## Phase 7: Content Pipeline

Goal: make curriculum authoring safe and repeatable.

Work:

- Add a content fixture format for skills, lessons, and exercises. Done with `services/api/scripts/curriculum.ts`.
- Validate every exercise through `ExercisePayloadZ`. Done with fixture builders and API curriculum tests.
- Generate solutions from the Morse codec where possible. Done for seed match/send/translate payloads.
- Add content import script.
- Add content authoring docs with examples for every exercise kind.
- Add seed data for at least one complete beginner unit. Done with four `Foundations` lessons and 20 exercises.

Acceptance:

```bash
task seed
task test
```

Content requirements:

- At least one complete skill with multiple lessons.
- Every exercise has valid payload JSON.
- Seed can be run repeatedly without duplicate content.

## Phase 8: Observability and Operations

Goal: make staging/prod diagnosable.

Work:

- Add structured operation names and request IDs to GraphQL logs.
- Add `/metrics` with real Prometheus counters/histograms.
- Add DB query timing instrumentation.
- Add OpenTelemetry wiring behind env flags.
- Add staging deploy script.
- Write backup/restore scripts.
- Add Grafana dashboard JSON stubs.

Acceptance:

- Health, readiness, logs, and metrics work in staging.
- Slow `completeLesson` calls can be traced to resolver/domain/DB time.
- A restore drill can run from documented commands.

## Phase 9: TestFlight Readiness

Goal: produce a signed internal TestFlight build.

Work:

- Add Apple Developer team ID and signing config.
- Add Fastlane lanes for internal beta.
- Verify privacy manifest and required-reason APIs.
- Add account deletion UI and API confirmation.
- Add basic onboarding.
- Add App Store screenshots later.
- Add crash/hang capture through MetricKit.

Acceptance:

```bash
task app
cd apps/ios && bundle exec fastlane beta
```

Release checks:

- No placeholder app icon/launch behavior.
- Privacy manifest passes archive validation.
- Account deletion is reachable in-app.
- Internal TestFlight install can sign in and complete the seeded lesson.

## Phase 10: Production Launch

Goal: launch a small public beta with controlled operational risk.

Work:

- Provision staging and prod VPS.
- Configure Postgres, Caddy, systemd, backups, and firewall.
- Deploy API to staging from `main`.
- Deploy web preview/staging.
- Add manual approval for prod deploy tags.
- Add runbook entries for deploy, rollback, backup restore, and incidents.

Acceptance:

- Staging mirrors production topology.
- Prod deploy can roll back on failed health checks.
- Nightly backups and WAL archive are verified.
- Public TestFlight users can complete the first skill without developer intervention.

## Ongoing Quality Gates

Run before merging meaningful changes:

```bash
task codegen
task check
task test
```

Use `task build` before broad app-facing handoffs.

Run before iOS-focused changes are considered done:

```bash
task app
task uitest
xcodebuild -quiet -scheme Dahdit-Dev \
  -project apps/ios/Dahdit.xcodeproj \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Run before web-focused changes are considered done:

```bash
task site
cd apps/web && bun test
```

Run before API-focused changes are considered done:

```bash
task migrate
task seed
cd services/api && bun test
cd services/api && bun run typecheck
```

## Near-Term Backlog

Highest priority:

1. Run a manual network-disconnect simulator smoke for the new offline `completeLesson` retry path.
2. Verify audio quality and haptics on simulator/device for lesson and Practice flows.
3. Verify signed simulator/device Keychain behavior without the DEBUG UserDefaults fallback.
4. Add replay tracking plus wrong-answer and Practice haptic feedback to exercise/review logs.
5. Run responsive/accessibility QA on the web learner station.

Second priority:

1. Add Swift snapshot or UI tests for core lesson screens.
2. Add golden audio tests.
3. Add staging deploy scripts and production secret documentation.

Deferred:

- Apple Sign In/passkeys.
- Hardware key integration.
- Multiplayer.
- Managed Postgres migration.
- Full App Store screenshot pipeline.
