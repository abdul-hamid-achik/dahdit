import { describe, expect, test } from 'bun:test'
import { encodeMorse, ExercisePayloadZ, symbolsToCode } from '@dahdit/morse-core'
import { allCurriculumExercises, curriculum } from '../scripts/curriculum'

describe('seed curriculum', () => {
  test('contains a complete beginner Foundations skill', () => {
    const foundations = curriculum.find((skill) => skill.slug === 'foundations')

    expect(foundations).toBeDefined()
    expect(foundations?.position).toBe(0)
    expect(foundations?.lessons.length).toBeGreaterThanOrEqual(4)
    expect(foundations?.lessons.map((lesson) => lesson.position)).toEqual([0, 1, 2, 3])
  })

  test('keeps the first lesson contract stable for UI automation', () => {
    const firstLesson = curriculum[0]?.lessons[0]

    expect(firstLesson?.slug).toBe('first-signals')
    expect(firstLesson?.title).toBe('First Signals')
    expect(firstLesson?.exercises.map((exercise) => exercise.kind)).toEqual([
      'matchCharacterToCode',
      'listenAndType',
      'tapTheCode',
      'translateToMorse',
      'copyAtSpeed',
    ])
  })

  test('has unique lesson slugs and positions inside each skill', () => {
    for (const skill of curriculum) {
      const slugs = new Set(skill.lessons.map((lesson) => lesson.slug))
      const positions = new Set(skill.lessons.map((lesson) => lesson.position))

      expect(slugs.size).toBe(skill.lessons.length)
      expect(positions.size).toBe(skill.lessons.length)
    }
  })

  test('validates every exercise payload and generated solution', () => {
    for (const payload of allCurriculumExercises()) {
      expect(() => ExercisePayloadZ.parse(payload)).not.toThrow()

      if (payload.kind === 'matchCharacterToCode') {
        expect(payload.solution.correctIndex).toBeLessThan(payload.prompt.options.length)
        expect(payload.prompt.options[payload.solution.correctIndex]).toBe(
          symbolsToCode(encodeMorse(payload.prompt.character)),
        )
      }

      if (payload.kind === 'tapTheCode') {
        const expected = encodeMorse(payload.prompt.character).filter(
          (symbol) => symbol === 'dit' || symbol === 'dah',
        )
        expect(payload.solution.symbols).toEqual(expected)
      }

      if (payload.kind === 'translateToMorse') {
        expect(payload.solution.symbols).toEqual(encodeMorse(payload.prompt.text))
      }

      if (payload.kind === 'listenAndType' || payload.kind === 'copyAtSpeed') {
        expect(payload.solution.accept).toContain(payload.prompt.text)
      }
    }
  })
})
