# Dahdit Runbook

## Local Development

1. `cp .env.example .env`
2. `task setup`
3. `task dev`
4. `task ios`

The API runs at `http://localhost:4000/graphql`. The web app runs through Vite+/Nuxt.

`task setup` uses Bun directly for installation. The pinned Vite+ alpha remains available for selected web tooling, but `vp install` is not used because it does not support Bun as the package manager.

The iOS project is generated with XcodeGen. `task ios` and `task app` regenerate `apps/ios/Dahdit.xcodeproj`; use `task xcode` directly after adding Swift files.

## Health Checks

- API liveness: `curl http://localhost:4000/health`
- API readiness: `curl http://localhost:4000/ready`
- GraphQL IDE: `http://localhost:4000/graphql` in development
- Full local API smoke: `task smoke`

`task smoke` expects the API and Postgres to already be running. It signs up a disposable smoke user, logs in, verifies refresh-token rotation and reuse rejection, fetches the skill tree, starts the first unlocked lesson, completes it with valid answers, and checks the leaderboard.

## Database

- Generate migrations: `task migration`
- Apply migrations: `task migrate`
- Seed curriculum: `task seed`

Local Postgres is built from `infra/postgres/Dockerfile` so the container has `pg_cron` installed. Compose starts Postgres with `shared_preload_libraries=pg_cron` and `cron.database_name=dahdit`.

## Environment

The API validates required environment variables at startup through `services/api/src/config.ts`.

Local:

- `DATABASE_URL=postgres://dahdit:dahdit@localhost:5432/dahdit` for host-run scripts.
- `JWT_SECRET=dev-only-jwt-secret-min-32-chars-long-x` is only acceptable for local development.
- `CORS_ORIGINS=http://localhost:3000,http://localhost:3001`.

Staging and production:

- Use a unique Postgres URL per environment.
- Use a strong 32+ character `JWT_SECRET`; do not reuse the local value.
- Set `NODE_ENV=production` for deployed API processes.
- Set `CORS_ORIGINS` to the exact web origins for that environment.
- Keep secrets in the deployment secret store, not in committed files.

## Builds

- Build everything: `task build`
- Build web only: `task site`
- Build iOS only: `task app`
- Regenerate Xcode project only: `task xcode`

## iOS Simulator Smoke

For local simulator verification with the API running:

```bash
xcodebuild -scheme Dahdit-Dev \
  -project apps/ios/Dahdit.xcodeproj \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO build
```

Then install and launch the built app from DerivedData, or run through Xcode. The current smoke target is:

- Sign up against `http://localhost:4000/graphql`.
- Confirm the seeded `Foundations` skill and `First Signals` lesson render.
- Open the lesson.
- Complete `matchCharacterToCode`.
- Tap Play on `listenAndType`, then complete it with `ET`.
- Complete `tapTheCode` with the manual `Dit`/`Dah` controls.
- Complete `translateToMorse` with manual dit/dah plus character-gap controls.
- Tap Play on `copyAtSpeed`, then submit the accepted text.
- Confirm the completion screen shows server-returned XP/streak.

Unsigned simulator builds may use the app's DEBUG-only token fallback if Keychain writes fail. Signed simulator/device builds should use Keychain.

## Local Stack Verification

After `task dev` is running in another terminal:

```bash
curl -fsS http://localhost:4000/health
curl -fsS http://localhost:4000/ready
task smoke
```

## Production Recovery Sketch

1. Provision a replacement VPS.
2. Install Postgres 17, pg_cron, pgcrypto, citext, Caddy, Bun, and the service user.
3. Restore the latest `pgBackRest` backup.
4. Deploy the latest API release tarball.
5. Point Cloudflare DNS to the replacement host.
6. Verify `/health`, `/ready`, login, and `completeLesson`.

## Release Tags

- API: `api-v0.x.y`
- Web: `web-v0.x.y`
- iOS/TestFlight: `ios-v0.x.y`
