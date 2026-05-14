# Content Authoring

Exercises are stored as JSON payloads and validated by `ExercisePayloadZ` in `packages/morse-core/src/exercises.ts`.

## Rules

- Every payload must include a `kind` discriminator.
- `listenAndType` and `copyAtSpeed` prompts include timing.
- `tapTheCode` is single-character.
- `translateToMorse` accepts the full symbol stream, including `charGap` and `wordGap`.
- Copy tolerance is Levenshtein based and defaults to one edit per five characters.

## Seed Content

The initial development curriculum is declared in `services/api/scripts/curriculum.ts`.
`services/api/scripts/seed.ts` imports that fixture and upserts skills, lessons, and exercises
by stable slug/position so it can be run repeatedly without creating duplicate rows.

Run:

```bash
task seed
```

## Adding a Lesson

1. Add a lesson object in `services/api/scripts/curriculum.ts`.
2. Add ordered exercise payloads using the local helpers where possible.
3. Generate Morse solutions with `encodeMorse(...)` instead of typing symbol arrays by hand.
4. Run `task seed` locally and complete the lesson through GraphQL.
5. Run `cd services/api && bun test` so the curriculum fixture tests catch payload or ordering mistakes.
