import { symbolsToCode, encodeMorse } from '@dahdit/morse-core'
import { closeDb, db } from '../src/db/client'
import { exercises, lessons, skills } from '../src/db/schema'
import { curriculum } from './curriculum'

let lessonCount = 0
let exerciseCount = 0

for (const skillSeed of curriculum) {
  const [skill] = await db
    .insert(skills)
    .values({
      slug: skillSeed.slug,
      title: skillSeed.title,
      description: skillSeed.description,
      position: skillSeed.position,
    })
    .onConflictDoUpdate({
      target: skills.slug,
      set: {
        title: skillSeed.title,
        description: skillSeed.description,
        position: skillSeed.position,
      },
    })
    .returning()

  if (!skill) throw new Error(`Could not seed skill ${skillSeed.slug}`)

  for (const lessonSeed of skillSeed.lessons) {
    const [lesson] = await db
      .insert(lessons)
      .values({
        skillId: skill.id,
        slug: lessonSeed.slug,
        title: lessonSeed.title,
        position: lessonSeed.position,
        xpReward: lessonSeed.xpReward,
      })
      .onConflictDoUpdate({
        target: [lessons.skillId, lessons.position],
        set: {
          slug: lessonSeed.slug,
          title: lessonSeed.title,
          xpReward: lessonSeed.xpReward,
        },
      })
      .returning()

    if (!lesson) throw new Error(`Could not seed lesson ${lessonSeed.slug}`)
    lessonCount += 1

    for (const [position, payload] of lessonSeed.exercises.entries()) {
      await db
        .insert(exercises)
        .values({
          lessonId: lesson.id,
          kind: payload.kind,
          position,
          payload,
        })
        .onConflictDoUpdate({
          target: [exercises.lessonId, exercises.position],
          set: {
            kind: payload.kind,
            payload,
          },
        })
      exerciseCount += 1
    }
  }
}

console.log(
  `Seeded ${curriculum.length} skill, ${lessonCount} lessons, and ${exerciseCount} exercises. SOS is ${symbolsToCode(
    encodeMorse('SOS'),
  )}`,
)
await closeDb()
