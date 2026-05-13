# Content Authoring

Exercises are stored as JSON payloads and validated by `ExercisePayloadZ` in `packages/morse-core/src/exercises.ts`.

## Rules

- Every payload must include a `kind` discriminator.
- `listenAndType` and `copyAtSpeed` prompts include timing.
- `tapTheCode` is single-character.
- `translateToMorse` accepts the full symbol stream, including `charGap` and `wordGap`.
- Copy tolerance is Levenshtein based and defaults to one edit per five characters.

## Seed Content

The initial development curriculum is in `services/api/scripts/seed.ts`.

Run:

```bash
task db:seed
```

## Adding a Lesson

1. Add a `lessons` row for the target skill.
2. Add ordered `exercises` rows.
3. Validate each payload with `ExercisePayloadZ.parse(...)`.
4. Run `task db:seed` locally and complete the lesson through GraphQL.

