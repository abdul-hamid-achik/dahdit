import { eq } from 'drizzle-orm'
import { exercises, lessons } from '../../db/schema'
import { builder } from '../builder'
import { ExerciseRef, LessonRef } from '../types/objects'

builder.queryField('lesson', (t) =>
  t.field({
    type: LessonRef,
    nullable: true,
    authScopes: { authenticated: true },
    args: {
      id: t.arg.string({ required: true }),
    },
    resolve: (_root, { id }, ctx) =>
      ctx.db.query.lessons.findFirst({
        where: eq(lessons.id, id),
      }),
  }),
)

builder.queryField('lessonExercises', (t) =>
  t.field({
    type: [ExerciseRef],
    authScopes: { authenticated: true },
    args: {
      lessonId: t.arg.string({ required: true }),
    },
    resolve: (_root, { lessonId }, ctx) =>
      ctx.db.query.exercises.findMany({
        where: eq(exercises.lessonId, lessonId),
        orderBy: (table, { asc }) => [asc(table.position)],
      }),
  }),
)

