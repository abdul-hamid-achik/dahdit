import { describe, expect, test } from 'bun:test'
import vectors from '../test-vectors/srs.json'
import { scheduleNext, type ReviewCard, type ReviewGrade } from '../src'

describe('SM-2 lite scheduler', () => {
  for (const vector of vectors) {
    test(`${vector.card.cardKey} ${vector.grade}`, () => {
      expect(
        scheduleNext(vector.card as ReviewCard, vector.grade as ReviewGrade, new Date(vector.today)),
      ).toEqual(vector.expected as ReviewCard)
    })
  }
})
