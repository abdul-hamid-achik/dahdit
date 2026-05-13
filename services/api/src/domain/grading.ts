import {
  audioDurationMs,
  encodeMorse,
  ExercisePayloadZ,
  isAnswerCorrect,
  type ExercisePayload,
} from '@dahdit/morse-core'

export type ValidationFlag =
  | 'IMPLAUSIBLY_FAST'
  | 'ANSWER_BEFORE_AUDIO_DONE'
  | 'STALE_ATTEMPT'
  | 'SUSPICIOUSLY_UNIFORM'
  | 'CLIENT_LIED'

export interface ExerciseForGrading {
  id: string
  payload: unknown
}

export interface ExerciseAttemptLog {
  exerciseId: string
  correct: boolean
  timeMs: number
  answer: unknown
}

export interface ValidatedExercise {
  exerciseId: string
  correct: boolean
  timeMs: number
  answer: unknown
  flags: ValidationFlag[]
  payload: ExercisePayload
}

export interface ValidatedAttempt {
  perExercise: ValidatedExercise[]
  cheatScore: number
  hardReject: boolean
}

export function gradeAttempt(
  exercises: ExerciseForGrading[],
  log: ExerciseAttemptLog[],
): ValidatedAttempt {
  const exerciseById = new Map(exercises.map((exercise) => [exercise.id, exercise]))
  const perExercise = log
    .filter((entry) => exerciseById.has(entry.exerciseId))
    .map((entry) => validateEntry(exerciseById.get(entry.exerciseId)!, entry))

  const fastCount = perExercise.filter((entry) => entry.flags.includes('IMPLAUSIBLY_FAST')).length
  const totalTime = perExercise.reduce((sum, entry) => sum + entry.timeMs, 0)
  const hardReject =
    perExercise.length > 0 &&
    (fastCount / perExercise.length > 0.5 || (perExercise.length >= 10 && totalTime < 2000))

  if (hasSuspiciousUniformTiming(perExercise)) {
    for (const entry of perExercise) entry.flags.push('SUSPICIOUSLY_UNIFORM')
  }

  const flagWeights: Record<ValidationFlag, number> = {
    IMPLAUSIBLY_FAST: 0.2,
    ANSWER_BEFORE_AUDIO_DONE: 0.2,
    STALE_ATTEMPT: 0.05,
    SUSPICIOUSLY_UNIFORM: 0.2,
    CLIENT_LIED: 0.35,
  }

  const rawScore = perExercise.reduce(
    (sum, entry) => sum + entry.flags.reduce((flagSum, flag) => flagSum + flagWeights[flag], 0),
    0,
  )
  const cheatScore = perExercise.length === 0 ? 0 : Math.min(1, rawScore / perExercise.length)

  return {
    perExercise,
    cheatScore,
    hardReject: hardReject || cheatScore > 0.5,
  }
}

function validateEntry(exercise: ExerciseForGrading, entry: ExerciseAttemptLog): ValidatedExercise {
  const payload = ExercisePayloadZ.parse(exercise.payload)
  const flags: ValidationFlag[] = []
  const timeMs = Math.min(Math.max(0, entry.timeMs), 5 * 60 * 1000)

  if (entry.timeMs < 200) flags.push('IMPLAUSIBLY_FAST')
  if (entry.timeMs > 5 * 60 * 1000) flags.push('STALE_ATTEMPT')

  if (
    (payload.kind === 'listenAndType' || payload.kind === 'copyAtSpeed') &&
    timeMs < audioDurationMsFromPayload(payload) * 0.5
  ) {
    flags.push('ANSWER_BEFORE_AUDIO_DONE')
  }

  const serverCorrect = isAnswerCorrect(payload, entry.answer)
  if (entry.correct && !serverCorrect) flags.push('CLIENT_LIED')

  return {
    exerciseId: entry.exerciseId,
    correct: serverCorrect,
    timeMs,
    answer: entry.answer,
    flags,
    payload,
  }
}

function audioDurationMsFromPayload(payload: ExercisePayload): number {
  if (payload.kind !== 'listenAndType' && payload.kind !== 'copyAtSpeed') return 0
  return audioDurationMs(
    encodeMorse(payload.prompt.text),
    payload.prompt.timing,
  )
}

function hasSuspiciousUniformTiming(entries: ValidatedExercise[]): boolean {
  if (entries.length < 5) return false
  const mean = entries.reduce((sum, entry) => sum + entry.timeMs, 0) / entries.length
  const variance =
    entries.reduce((sum, entry) => sum + (entry.timeMs - mean) ** 2, 0) / entries.length
  return Math.sqrt(variance) < 50
}
