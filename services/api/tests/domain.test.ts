import { describe, expect, test } from 'bun:test'
import { encodeMorse } from '@dahdit/morse-core'
import { gradeAttempt } from '../src/domain/grading'
import { computeXp } from '../src/domain/xp'
import { advanceStreak } from '../src/domain/streak'

describe('attempt grading', () => {
  test('forces claimed correct to false when the answer does not match', () => {
    const validated = gradeAttempt(
      [
        {
          id: 'e1',
          payload: {
            kind: 'listenAndType',
            prompt: { text: 'SOS', timing: { wpm: 15 } },
            solution: { accept: ['SOS'] },
          },
        },
      ],
      [{ exerciseId: 'e1', correct: true, timeMs: 5000, answer: 'SOO' }],
    )

    expect(validated.perExercise[0]?.correct).toBe(false)
    expect(validated.perExercise[0]?.flags).toContain('CLIENT_LIED')
  })

  test('caps XP on suspicious attempts', () => {
    const validated = gradeAttempt(
      [
        {
          id: 'e1',
          payload: {
            kind: 'translateToMorse',
            prompt: { text: 'SOS' },
            solution: { symbols: encodeMorse('SOS') },
          },
        },
      ],
      [{ exerciseId: 'e1', correct: true, timeMs: 100, answer: encodeMorse('SOS') }],
    )

    expect(validated.hardReject).toBe(true)
    expect(computeXp(validated)).toBeLessThanOrEqual(7)
  })
})

describe('streaks', () => {
  test('increments across consecutive user-local days', () => {
    expect(
      advanceStreak(
        { streakDays: 3, lastActiveOn: '2026-05-10' },
        'America/Monterrey',
        new Date('2026-05-11T17:00:00.000Z'),
      ),
    ).toEqual({ streakDays: 4, activeOn: '2026-05-11' })
  })
})

