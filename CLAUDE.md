# CLAUDE.md

Guidance for Claude Code and other AI coding assistants working in this repository.

## Project Overview

Dahdit is a Duolingo-style Morse code learning app. The MVP has three main surfaces:

- **`apps/ios`**: Native iOS app, Swift 6, SwiftUI, local SPM packages.
- **`services/api`**: Bun API, Hono, GraphQL Yoga, Pothos, Drizzle, Postgres.
- **`apps/web`**: Nuxt companion app for marketing, API-backed dashboard, and public demos.

Shared domain logic lives in:

- **`packages/morse-core`**: TypeScript Morse codec, exercise schemas, send timing, SRS.
- **`apps/ios/Packages/DahditCore`**: Swift mirror of the same core behavior.
- **`packages/shared-types`**: Printed GraphQL schema, operations, generated TS types.

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

## Repository Conventions

- Prefer `rg` and `rg --files` for searches.
- Use `apply_patch` for manual edits.
- Keep edits scoped to the requested task.
- Do not rewrite generated files by hand unless the generator is unavailable and the change is clearly temporary.
- Do not commit secrets. Use `.env.example` for documented local configuration.
- Preserve ASCII in new files unless there is a strong reason not to.
- Do not revert unrelated user changes.

## Architecture Guardrails

### Backend

- Drizzle schema is the database source of truth.
- Pothos/Yoga schema is code-first and printed through `task schema`.
- Domain logic belongs in `services/api/src/domain`.
- Resolvers should orchestrate; they should not become large business-logic modules.
- The server is authoritative for XP, streaks, hearts, unlocks, and SRS.
- Never trust client-provided correctness or XP.

### iOS

- Keep pure domain code in `DahditCore`.
- Keep AVAudioEngine/Core Haptics in `DahditAudio`.
- Keep reusable SwiftUI primitives in `DahditUI`.
- Keep screen-level views and feature view models in the app target.
- Use Swift 6 strict concurrency patterns. Actor-isolate stateful services.
- All gesture-only interactions need accessible button alternatives.

### Web

- The first screen should remain a usable product/demo surface, not just a marketing page.
- Keep the Morse preview code-native and interactive.
- Use Nuxt scripts from `apps/web/package.json` for build/test/check.
- Avoid adding large decorative UI patterns that do not support the product workflow.

### Shared Logic

- Update both TS and Swift implementations when changing Morse codec, SRS, or send timing behavior.
- Update shared JSON vectors first when behavior intentionally changes.
- Keep payload schemas in `packages/morse-core/src/exercises.ts` as the canonical exercise contract.

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

## Project Structure

```
dahdit/
├── apps/
│   ├── ios/                    # Swift 6 iOS app
│   │   ├── Dahdit.xcodeproj/   # Generated by XcodeGen
│   │   ├── project.yml         # XcodeGen spec
│   │   └── Packages/
│   │       ├── DahditCore/     # Swift Morse codec, SRS, exercise models
│   │       ├── DahditAudio/    # AVAudioEngine, Core Haptics
│   │       ├── DahditGraphQL/  # Apollo-generated operations + tests
│   │       └── DahditUI/       # Reusable SwiftUI primitives
│   └── web/                    # Nuxt companion app
├── packages/
│   ├── morse-core/             # TS Morse codec, exercise schemas, SRS
│   ├── shared-types/           # Generated GraphQL types + operations
│   └── tsconfig/               # Shared TS config
├── services/
│   └── api/                    # Bun API server
│       ├── src/
│       │   ├── domain/         # Business logic (grading, SRS, XP, streaks)
│       │   ├── graphql/        # Pothos schema, resolvers
│       │   └── db/             # Drizzle schema, migrations
│       └── scripts/            # seed, smoke, print-schema, curriculum
├── infra/
│   └── postgres/               # Custom Postgres image with pg_cron
├── docs/
│   ├── adr/                    # Architecture Decision Records
│   ├── runbook.md              # Operational commands
│   └── content-authoring.md    # Exercise/content rules
├── docker-compose.yml
├── Taskfile.yml
├── package.json
└── .env.example
```

## Key Technical Details

### API

- **Framework**: Hono + GraphQL Yoga + Pothos (code-first GraphQL)
- **Database**: Postgres 17 with pg_cron, accessed via Drizzle ORM
- **Auth**: JWT access/refresh tokens with family reuse detection
- **Port**: 4000 (configurable via `API_PORT`)
- **Health**: `/health` (liveness), `/ready` (readiness)
- **Dev-only endpoint**: `POST /__test/seed-review` (disabled in production)

### iOS

- **Project generation**: XcodeGen from `project.yml`
- **GraphQL client**: Apollo iOS 2.1.1 with generated operations
- **Auth storage**: Keychain (primary), UserDefaults fallback (DEBUG only)
- **Local persistence**: SwiftData for lesson drafts, audio settings
- **Token refresh**: `TokenRefreshCoordinator` serializes refresh, retries failed ops once
- **Offline**: Failed `completeLesson` calls persist as drafts, retry on foreground/lesson start

### Web

- **Framework**: Nuxt with Vite+ (pinned alpha)
- **Package manager**: Bun (Vite+ alpha does not support `vp install` with Bun)
- **Auth**: Email/password with token refresh
- **Dashboard**: Real API-backed stats, skill tree, due reviews, leaderboard

### Docker Compose

- **postgres**: Custom image with pg_cron, port `${POSTGRES_PORT:-5432}`
- **api**: Bun API with watch mode for `src/` and `packages/morse-core/src/`
- **mailpit**: SMTP testing on ports 1025/8025

## Current State & Known Gaps

The project has a working local vertical slice. Key known gaps:

1. **Audio/haptics QA**: Deeper audio quality and haptics need simulator/device verification
2. **Offline smoke**: Manual network-disconnect simulator smoke for `completeLesson` retry is pending
3. **Keychain verification**: Signed simulator/device Keychain behavior without DEBUG fallback needs testing
4. **Replay telemetry**: Wrong-answer and Practice haptic feedback not yet implemented
5. **Web QA**: Responsive/accessibility QA on web learner station is pending
6. **TestFlight**: No signing config, Fastlane lanes, or device validation yet
7. **Staging/prod**: No staging deploy, production secrets, backups, or monitoring

## Documentation

Keep these files aligned when behavior changes:

- `ROADMAP.md`: build plan and acceptance gates
- `docs/runbook.md`: operational commands
- `docs/content-authoring.md`: exercise/content rules
- `docs/adr/*`: architecture decisions
- `Taskfile.yml`: command source of truth
