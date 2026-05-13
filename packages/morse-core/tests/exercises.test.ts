import { describe, expect, test } from 'bun:test'
import { ExercisePayloadZ, isAnswerCorrect } from '../src'

describe('exercise payloads', () => {
  test('validates listen-and-type payloads', () => {
    const payload = ExercisePayloadZ.parse({
      kind: 'listenAndType',
      prompt: { text: 'SOS', timing: { wpm: 15 } },
      solution: { accept: ['SOS'] },
    })

    expect(isAnswerCorrect(payload, 'sos')).toBe(true)
    expect(isAnswerCorrect(payload, 'soo')).toBe(false)
  })

  test('applies copy-at-speed tolerance', () => {
    const payload = ExercisePayloadZ.parse({
      kind: 'copyAtSpeed',
      prompt: { text: 'CQ CQ DE DAHDIT', timing: { wpm: 15 }, durationSec: 20 },
      solution: { accept: ['CQ CQ DE DAHDIT'], toleranceLevenshteinPer5Chars: 1 },
    })

    expect(isAnswerCorrect(payload, 'CQ CQ DE DAHDUT')).toBe(true)
  })
})

