import {
  cardKeysForText,
  newReviewCard,
  scheduleNext,
  type CardKey,
  type ReviewCard,
  type ReviewGrade,
} from '@dahdit/morse-core'
import type { ValidatedAttempt, ValidatedExercise } from './grading'

export interface ReviewCardRow {
  userId: string
  cardKey: string
  ease: number
  intervalDays: number
  dueOn: string
}

export function scheduleReviewsFor(
  userId: string,
  validated: ValidatedAttempt,
  existing: Map<string, ReviewCardRow>,
  today: Date,
): ReviewCard[] {
  const updates = new Map<CardKey, ReviewCard>()

  for (const exercise of validated.perExercise) {
    for (const cardKey of cardsForExercise(exercise)) {
      const current = existingCard(userId, cardKey, existing.get(cardKey), today)
      updates.set(cardKey, scheduleNext(current, gradeForExercise(exercise), today))
    }
  }

  return [...updates.values()]
}

function cardsForExercise(exercise: ValidatedExercise): CardKey[] {
  const payload = exercise.payload
  switch (payload.kind) {
    case 'listenAndType':
    case 'copyAtSpeed':
    case 'translateToMorse':
      return cardKeysForText(payload.prompt.text)
    case 'tapTheCode':
    case 'matchCharacterToCode':
      return cardKeysForText(payload.prompt.character)
  }
}

function gradeForExercise(exercise: ValidatedExercise): ReviewGrade {
  if (!exercise.correct) return 'again'
  if (exercise.flags.length > 0) return 'hard'
  if (exercise.timeMs < 1500) return 'easy'
  return 'good'
}

function existingCard(
  userId: string,
  cardKey: CardKey,
  row: ReviewCardRow | undefined,
  today: Date,
): ReviewCard {
  if (!row) return newReviewCard(userId, cardKey, today)
  return {
    userId,
    cardKey,
    ease: row.ease / 100,
    intervalDays: row.intervalDays,
    dueOn: row.dueOn,
  }
}

