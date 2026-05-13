import { encodeMorse, ExercisePayloadZ, symbolsToCode } from '@dahdit/morse-core'
import { db, closeDb } from '../src/db/client'
import { exercises, lessons, skills } from '../src/db/schema'

const foundations = await db
  .insert(skills)
  .values({
    slug: 'foundations',
    title: 'Foundations',
    description: 'Hear and recognize E, T, A, N, and SOS.',
    position: 0,
  })
  .onConflictDoNothing()
  .returning()

const skill =
  foundations[0] ??
  (await db.query.skills.findFirst({
    where: (table, { eq }) => eq(table.slug, 'foundations'),
  }))

if (!skill) throw new Error('Could not seed skill')

const [lesson] = await db
  .insert(lessons)
  .values({
    skillId: skill.id,
    slug: 'first-signals',
    title: 'First Signals',
    position: 0,
    xpReward: 10,
  })
  .onConflictDoNothing()
  .returning()

const lessonRow =
  lesson ??
  (await db.query.lessons.findFirst({
    where: (table, { eq }) => eq(table.slug, 'first-signals'),
  }))

if (!lessonRow) throw new Error('Could not seed lesson')

const payloads = [
  ExercisePayloadZ.parse({
    kind: 'matchCharacterToCode',
    prompt: { character: 'E', options: ['.', '-', '.-', '-.'] },
    solution: { correctIndex: 0 },
  }),
  ExercisePayloadZ.parse({
    kind: 'listenAndType',
    prompt: { text: 'ET', timing: { wpm: 12, farnsworthWpm: 8 } },
    solution: { accept: ['ET'] },
  }),
  ExercisePayloadZ.parse({
    kind: 'tapTheCode',
    prompt: { character: 'A' },
    solution: { symbols: ['dit', 'dah'] },
  }),
  ExercisePayloadZ.parse({
    kind: 'translateToMorse',
    prompt: { text: 'SOS' },
    solution: { symbols: encodeMorse('SOS') },
  }),
  ExercisePayloadZ.parse({
    kind: 'copyAtSpeed',
    prompt: { text: 'CQ CQ DE DAHDIT', timing: { wpm: 12, farnsworthWpm: 8 }, durationSec: 20 },
    solution: { accept: ['CQ CQ DE DAHDIT'], toleranceLevenshteinPer5Chars: 1 },
  }),
]

for (const [position, payload] of payloads.entries()) {
  await db
    .insert(exercises)
    .values({
      lessonId: lessonRow.id,
      kind: payload.kind,
      position,
      payload,
    })
    .onConflictDoNothing()
}

console.log(`Seeded ${payloads.length} exercises. SOS is ${symbolsToCode(encodeMorse('SOS'))}`)
await closeDb()

