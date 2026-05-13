import { z } from 'zod'

export const TimingZ = z.object({
  wpm: z.number().min(5).max(40),
  farnsworthWpm: z.number().min(5).max(40).optional(),
  toneHz: z.number().min(400).max(900).default(700),
})

export const ListenAndTypePayloadZ = z.object({
  kind: z.literal('listenAndType'),
  prompt: z.object({ text: z.string().min(1).max(40), timing: TimingZ }),
  solution: z.object({ accept: z.array(z.string()).min(1) }),
})

export const TapTheCodePayloadZ = z.object({
  kind: z.literal('tapTheCode'),
  prompt: z.object({ character: z.string().length(1) }),
  solution: z.object({ symbols: z.array(z.enum(['dit', 'dah'])) }),
})

export const MatchCharacterToCodePayloadZ = z.object({
  kind: z.literal('matchCharacterToCode'),
  prompt: z.object({
    character: z.string().length(1),
    options: z.array(z.string()).min(2).max(6),
  }),
  solution: z.object({ correctIndex: z.number().int().nonnegative() }),
})

export const TranslateToMorsePayloadZ = z.object({
  kind: z.literal('translateToMorse'),
  prompt: z.object({ text: z.string().min(1).max(10) }),
  solution: z.object({
    symbols: z.array(z.enum(['dit', 'dah', 'charGap', 'wordGap'])),
  }),
})

export const CopyAtSpeedPayloadZ = z.object({
  kind: z.literal('copyAtSpeed'),
  prompt: z.object({
    text: z.string().min(5).max(120),
    timing: TimingZ,
    durationSec: z.number().int().min(10).max(120),
  }),
  solution: z.object({
    accept: z.array(z.string()).min(1),
    toleranceLevenshteinPer5Chars: z.number().int().min(0).max(2).default(1),
  }),
})

export const ExercisePayloadZ = z.discriminatedUnion('kind', [
  ListenAndTypePayloadZ,
  TapTheCodePayloadZ,
  MatchCharacterToCodePayloadZ,
  TranslateToMorsePayloadZ,
  CopyAtSpeedPayloadZ,
])

export type TimingPayload = z.infer<typeof TimingZ>
export type ExercisePayload = z.infer<typeof ExercisePayloadZ>
export type ExerciseKind = ExercisePayload['kind']

export function parseExercisePayload(value: unknown): ExercisePayload {
  return ExercisePayloadZ.parse(value)
}

export function isAnswerCorrect(payload: ExercisePayload, answer: unknown): boolean {
  switch (payload.kind) {
    case 'listenAndType':
      return typeof answer === 'string' && matchesAcceptedText(payload.solution.accept, answer)
    case 'copyAtSpeed':
      return (
        typeof answer === 'string' &&
        payload.solution.accept.some((accepted) => {
          const tolerance =
            Math.ceil(accepted.length / 5) * payload.solution.toleranceLevenshteinPer5Chars
          return levenshtein(normalizeText(accepted), normalizeText(answer)) <= tolerance
        })
      )
    case 'tapTheCode':
      return (
        Array.isArray(answer) &&
        answer.join(',') === payload.solution.symbols.join(',') &&
        answer.every((item) => item === 'dit' || item === 'dah')
      )
    case 'translateToMorse':
      return Array.isArray(answer) && answer.join(',') === payload.solution.symbols.join(',')
    case 'matchCharacterToCode':
      return Number(answer) === payload.solution.correctIndex
  }
}

function matchesAcceptedText(accepted: string[], answer: string): boolean {
  return accepted.map(normalizeText).includes(normalizeText(answer))
}

function normalizeText(value: string): string {
  return value.trim().replace(/\s+/g, ' ').toUpperCase()
}

export function levenshtein(left: string, right: string): number {
  const rows = left.length + 1
  const cols = right.length + 1
  const matrix = Array.from({ length: rows }, () => Array<number>(cols).fill(0))

  for (let i = 0; i < rows; i += 1) matrix[i]![0] = i
  for (let j = 0; j < cols; j += 1) matrix[0]![j] = j

  for (let i = 1; i < rows; i += 1) {
    for (let j = 1; j < cols; j += 1) {
      const cost = left[i - 1] === right[j - 1] ? 0 : 1
      matrix[i]![j] = Math.min(
        matrix[i - 1]![j]! + 1,
        matrix[i]![j - 1]! + 1,
        matrix[i - 1]![j - 1]! + cost,
      )
    }
  }

  return matrix[left.length]![right.length]!
}

