# AGENTS.md

Guidance for AI agents and contributors working in this repository.

## Project Snapshot

Dahdit is a Duolingo-style Morse code learning app. The MVP has three main surfaces:

- `apps/ios`: native iOS app, Swift 6, SwiftUI, local SPM packages.
- `services/api`: Bun API, Hono, GraphQL Yoga, Pothos, Drizzle, Postgres.
- `apps/web`: Nuxt companion app for marketing, dashboard, and public demos.

Shared domain logic lives in:

- `packages/morse-core`: TypeScript Morse codec, exercise schemas, send timing, SRS.
- `apps/ios/Packages/DahditCore`: Swift mirror of the same core behavior.
- `packages/shared-types`: printed GraphQL schema, operations, generated TS types.

Keep TypeScript and Swift Morse/SRS behavior in parity through shared JSON test vectors.

## Core Commands

Prefer the single-word Taskfile commands:

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
task migration   # generate Drizzle migrations
task migrate     # apply Drizzle migrations
task seed        # seed curriculum
task smoke       # run local API smoke test
task deploy      # web deploy
```

Compatibility aliases such as `task build:web`, `task build:ios`, and `task db:migrate` exist, but new docs and workflows should use the single-word commands.

## Tooling Notes

The Codex app shell may not include the user's normal PATH. If commands are missing, try:

```bash
PATH="$HOME/.bun/bin:/opt/homebrew/bin:$PATH" <command>
```

For Docker-related commands in the Codex app, this fuller PATH is often needed:

```bash
PATH="$HOME/.bun/bin:/opt/homebrew/bin:/usr/local/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH" <command>
```

If another local project already owns host port `5432`, run Dahdit Compose with a temporary override that exposes Postgres on `5433`, then point direct DB scripts at that port:

```bash
tmp=$(mktemp /tmp/dahdit-compose-XXXX.yml)
printf 'services:\n  postgres:\n    ports: !override\n      - "5433:5432"\n' > "$tmp"
docker compose -f docker-compose.yml -f "$tmp" up -d postgres api
rm -f "$tmp"
DATABASE_URL=postgres://dahdit:dahdit@localhost:5433/dahdit task smoke
```

Known local requirements:

- Bun 1.3+
- Task 3.50+
- Docker with Compose
- Xcode 26+
- XcodeGen 2.45+
- Swift 6+

Known current gaps:

- `task swiftgen` installs Apollo's bundled CLI on first run and generates Swift operation models into `DahditGraphQL`.
- iOS API calls use ApolloClient and generated operations. Startup token validation and one-shot per-request auth refresh/retry exist through `TokenRefreshCoordinator`; the forced expired-access-token retry path is covered by `DahditGraphQL` package tests.
- Unsigned simulator builds can fall back to DEBUG-only UserDefaults token storage if Keychain writes fail. Signed simulator/device/TestFlight builds must verify the real Keychain path.
- `listenAndType` and `copyAtSpeed` have app-side audio playback controls wired to `MorseAudioPlayer`; Practice now has one short audio-play UI smoke, but deeper lesson audio quality still needs simulator/device verification.
- `tapTheCode` and `translateToMorse` have manual symbol controls, and the seeded send exercises are covered by `task uitest`.
- Profile audio settings are persisted in SwiftData. Lesson playback applies the selected tone Hz, Practice playback uses selected WPM/Farnsworth/tone, and lesson send haptics honor the persisted haptics toggle.
- Practice has stable UI identifiers and is covered by `task uitest` through a seeded due review card. The test taps one short audio prompt; deeper audio quality and haptic verification still need simulator/device checks.
- Onboarding, home, lesson shell, all five exercise views, Practice, Leagues, Profile, loading, and error states share the first-pass Morse-game UI.
- Home HUD, Practice, Leagues, and Profile are API-backed through Apollo-generated operations. Practice has a first playable SRS review flow backed by `dueReviews` and `completeReviews`; richer variants, replay telemetry, and Practice haptic feedback still need work.
- Lesson attempts are persisted as SwiftData drafts. Failed `completeLesson` calls move into a pending sync state and retry when the app foregrounds or another lesson starts; the manual network-disconnect simulator smoke is still pending.
- Root auth validates stored tokens at startup, rotates through `refreshToken` when possible, and clears stale invalid sessions back to onboarding.
- `task ios` and `task app` run XcodeGen before opening/building. Run `task xcode` after adding Swift files if you are working directly in Xcode.
- iOS 26.5 simulator/device support is installed locally and `task app` currently builds.
- Docker Desktop must be running before Compose-based checks.
- The local API exposes `POST /__test/seed-review` outside production for UI automation only. Do not call it in staging or production workflows.
- Web scripts intentionally use Nuxt/Vitest directly. Vite+ remains pinned, but direct `vp build` is not the stable Nuxt build path.
- `task setup` uses Bun directly; do not replace it with `vp install` while Vite+ does not support Bun package manager installs.

## Verification Gates

Run before handing off meaningful changes:

```bash
task codegen
task check
task test
```

Run before broad or release-facing changes:

```bash
task build
```

Run for iOS-focused changes:

```bash
task app
task uitest
xcodebuild -quiet -scheme Dahdit-Dev \
  -project apps/ios/Dahdit.xcodeproj \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Run for web-focused changes:

```bash
task site
cd apps/web && bun test
```

Run for API-focused changes:

```bash
cd services/api && bun test
cd services/api && bun run typecheck
```

If Docker is available, also verify:

```bash
task setup
docker compose up -d api
curl -fsS http://localhost:4000/health
curl -fsS http://localhost:4000/ready
task smoke
```

## Repository Conventions

- Prefer `rg` and `rg --files` for searches.
- Use `apply_patch` for manual edits.
- Keep edits scoped to the requested task.
- Do not rewrite generated files by hand unless the generator is unavailable and the change is clearly temporary.
- Do not commit secrets. Use `.env.example` for documented local configuration.
- Preserve ASCII in new files unless there is a strong reason not to.
- Do not revert unrelated user changes.

## Architecture Guardrails

Backend:

- Drizzle schema is the database source of truth.
- Pothos/Yoga schema is code-first and printed through `task schema`.
- Domain logic belongs in `services/api/src/domain`.
- Resolvers should orchestrate; they should not become large business-logic modules.
- The server is authoritative for XP, streaks, hearts, unlocks, and SRS.
- Never trust client-provided correctness or XP.

iOS:

- Keep pure domain code in `DahditCore`.
- Keep AVAudioEngine/Core Haptics in `DahditAudio`.
- Keep reusable SwiftUI primitives in `DahditUI`.
- Keep screen-level views and feature view models in the app target.
- Use Swift 6 strict concurrency patterns. Actor-isolate stateful services.
- All gesture-only interactions need accessible button alternatives.

Web:

- The first screen should remain a usable product/demo surface, not just a marketing page.
- Keep the Morse preview code-native and interactive.
- Use Nuxt scripts from `apps/web/package.json` for build/test/check.
- Avoid adding large decorative UI patterns that do not support the product workflow.

Shared logic:

- Update both TS and Swift implementations when changing Morse codec, SRS, or send timing behavior.
- Update shared JSON vectors first when behavior intentionally changes.
- Keep payload schemas in `packages/morse-core/src/exercises.ts` as the canonical exercise contract.

## Current Priority Order

Follow `ROADMAP.md` for the full plan. Near-term priorities:

1. Verify deeper audio quality and haptics on simulator/device for lesson and Practice flows.
2. Add replay tracking plus wrong-answer and Practice haptic feedback to the lesson attempt and review flows.
3. Run a manual network-disconnect simulator smoke for the new offline `completeLesson` retry path.
4. Expand seed content to one complete beginner skill.
5. Verify signed simulator/device Keychain behavior without the DEBUG UserDefaults fallback.

## iOS Simulator Workflow

Use this for simulator smoke checks:

```bash
open -a Simulator
xcrun simctl boot "iPhone 16" || true
xcodebuild -scheme Dahdit-Dev \
  -project apps/ios/Dahdit.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

For the automated authenticated smoke on the current local simulator runtime:

```bash
task uitest
```

If using Computer Use, verify the simulator visually after launch:

- App launches without crashing.
- Home/skill tree renders.
- First lesson opens.
- Exercise UI responds to input.
- Lesson completion screen renders.

Current verified local slice:

- Signup reaches the authenticated app against local Docker API.
- Home renders the seeded `Foundations` skill and `First Signals` lesson.
- `task uitest` signs up through the real iOS UI on iPhone 17 / iOS 26.5, opens the seeded lesson, completes all five exercise kinds, submits `completeLesson`, and verifies the completion screen.
- The first lesson starts from the API.
- All five seeded exercise kinds progress through the lesson flow.
- `listenAndType` and `copyAtSpeed` playback buttons are wired to the shared audio service in code.
- `tapTheCode` and `translateToMorse` can be answered through explicit manual controls.
- Profile audio settings persist in SwiftData and feed playback/haptics: lesson tone Hz, Practice WPM/Farnsworth/tone, and lesson send haptics toggle.
- A first-pass game UI is in place for onboarding, home, lesson chrome, and exercise cards.
- Home HUD reads real profile stats, Practice reads `dueReviews`, Leagues reads `leaderboard`, and Profile reads `me.stats`.
- Practice can run a playable SRS review session and save grades through `completeReviews`; `task smoke` verifies the API path with a seeded due card.
- `task uitest` also covers Practice end to end with a dev-only seeded due card, one short audio play, typed copy, grade selection, and saved-state verification.
- `DahditAPI` uses ApolloClient and generated operations; raw GraphQL query strings have been removed from the iOS wrapper.
- Apollo custom `JSON` scalar decoding and fractional timestamp parsing are covered by `DahditGraphQL` package tests.
- `DahditAPI` retries auth failures once after a serialized refresh via `TokenRefreshCoordinator`.
- The forced expired-access-token retry path is covered with a mocked transport in `DahditGraphQL` tests.
- Lesson completion logs persist to SwiftData during a lesson, failed `completeLesson` submissions show "Saved for sync", and pending completion drafts retry on app start/foreground.
- `task smoke` verifies local API auth, token rotation/reuse rejection, lesson completion, SRS due reviews, review completion, leaderboard, account deletion, and deleted-token rejection.

Ask before taking externally visible actions such as TestFlight uploads, production deploys, or account deletion against non-local data.

## Documentation

Keep these files aligned when behavior changes:

- `ROADMAP.md`: build plan and acceptance gates.
- `docs/runbook.md`: operational commands.
- `docs/content-authoring.md`: exercise/content rules.
- `docs/adr/*`: architecture decisions.
- `Taskfile.yml`: command source of truth.
