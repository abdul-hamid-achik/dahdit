import type { ValidatedAttempt } from './grading'

export function computeXp(validated: ValidatedAttempt, baseXp = 10): number {
  if (validated.hardReject) return 0
  if (validated.perExercise.length === 0) return 0

  const correct = validated.perExercise.filter((entry) => entry.correct).length
  const accuracy = correct / validated.perExercise.length
  const perfectBonus = accuracy === 1 ? 5 : 0
  const raw = Math.round(baseXp * accuracy + perfectBonus)

  if (validated.cheatScore >= 0.3) return Math.floor(raw * 0.5)
  return raw
}

export function heartsLost(validated: ValidatedAttempt): number {
  return validated.perExercise.filter((entry) => !entry.correct).length
}
