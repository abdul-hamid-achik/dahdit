import {
  encodeMorse,
  ExercisePayloadZ,
  symbolsToCode,
  type ExercisePayload,
  type TimingPayload,
} from '@dahdit/morse-core'

export interface CurriculumSkill {
  slug: string
  title: string
  description: string
  position: number
  lessons: CurriculumLesson[]
}

export interface CurriculumLesson {
  slug: string
  title: string
  position: number
  xpReward: number
  exercises: ExercisePayload[]
}

const slowTiming: TimingPayload = { wpm: 12, farnsworthWpm: 8, toneHz: 700 }
const steadyTiming: TimingPayload = { wpm: 14, farnsworthWpm: 10, toneHz: 700 }

export const curriculum: CurriculumSkill[] = [
  {
    slug: 'foundations',
    title: 'Foundations',
    description: 'Beginner copy and send practice for E, T, A, N, I, M, S, O, and first call signs.',
    position: 0,
    lessons: [
      {
        slug: 'first-signals',
        title: 'First Signals',
        position: 0,
        xpReward: 10,
        exercises: [
          matchCharacterToCode('E', ['T', 'A', 'N']),
          listenAndType('ET', slowTiming),
          tapTheCode('A'),
          translateToMorse('SOS'),
          copyAtSpeed('CQ CQ DE DAHDIT', slowTiming, 20),
        ],
      },
      {
        slug: 'dit-pairs',
        title: 'Dit Pairs',
        position: 1,
        xpReward: 12,
        exercises: [
          matchCharacterToCode('I', ['E', 'S', 'M']),
          listenAndType('IN', slowTiming),
          tapTheCode('I'),
          translateToMorse('IN'),
          copyAtSpeed('IN IT IS', slowTiming, 18),
        ],
      },
      {
        slug: 'dah-pairs',
        title: 'Dah Pairs',
        position: 2,
        xpReward: 12,
        exercises: [
          matchCharacterToCode('M', ['T', 'N', 'A']),
          listenAndType('MO', steadyTiming),
          tapTheCode('N'),
          translateToMorse('TO'),
          copyAtSpeed('NO TO TOM', steadyTiming, 20),
        ],
      },
      {
        slug: 'calling-cq',
        title: 'Calling CQ',
        position: 3,
        xpReward: 15,
        exercises: [
          matchCharacterToCode('C', ['Q', 'D', 'K']),
          listenAndType('CQ', steadyTiming),
          tapTheCode('D'),
          translateToMorse('CQ'),
          copyAtSpeed('CQ CQ DE N0A', steadyTiming, 24),
        ],
      },
    ],
  },
]

export function allCurriculumExercises(): ExercisePayload[] {
  return curriculum.flatMap((skill) => skill.lessons.flatMap((lesson) => lesson.exercises))
}

function listenAndType(text: string, timing: TimingPayload): ExercisePayload {
  return ExercisePayloadZ.parse({
    kind: 'listenAndType',
    prompt: { text, timing },
    solution: { accept: [text] },
  })
}

function tapTheCode(character: string): ExercisePayload {
  const symbols = encodeMorse(character)
  return ExercisePayloadZ.parse({
    kind: 'tapTheCode',
    prompt: { character },
    solution: { symbols },
  })
}

function matchCharacterToCode(character: string, distractors: string[]): ExercisePayload {
  const options = [character, ...distractors].map((item) => symbolsToCode(encodeMorse(item)))
  return ExercisePayloadZ.parse({
    kind: 'matchCharacterToCode',
    prompt: { character, options },
    solution: { correctIndex: 0 },
  })
}

function translateToMorse(text: string): ExercisePayload {
  return ExercisePayloadZ.parse({
    kind: 'translateToMorse',
    prompt: { text },
    solution: { symbols: encodeMorse(text) },
  })
}

function copyAtSpeed(text: string, timing: TimingPayload, durationSec: number): ExercisePayload {
  return ExercisePayloadZ.parse({
    kind: 'copyAtSpeed',
    prompt: { text, timing, durationSec },
    solution: { accept: [text], toleranceLevenshteinPer5Chars: 1 },
  })
}
