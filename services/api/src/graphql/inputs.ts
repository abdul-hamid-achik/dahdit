import { builder } from './builder'

export const ExerciseResultInput = builder.inputType('ExerciseResultInput', {
  fields: (t) => ({
    exerciseId: t.string({ required: true }),
    correct: t.boolean({ required: true }),
    timeMs: t.int({ required: true }),
    answer: t.field({ type: 'JSON', required: true }),
  }),
})

export const ReviewResultInput = builder.inputType('ReviewResultInput', {
  fields: (t) => ({
    cardKey: t.string({ required: true }),
    grade: t.string({ required: true }),
  }),
})
