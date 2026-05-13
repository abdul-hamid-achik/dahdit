import { and, eq, inArray, sql } from 'drizzle-orm'
import { exercises, lessonAttempts, lessons, reviewCards, userStats } from '../../db/schema'
import { gradeAttempt, type ExerciseAttemptLog } from '../../domain/grading'
import { scheduleReviewsFor } from '../../domain/srs'
import { advanceStreak } from '../../domain/streak'
import { computeXp, heartsLost } from '../../domain/xp'
import { ForbiddenError, NotFoundError, ValidationError } from '../../lib/errors'
import { builder } from '../builder'
import { ExerciseResultInput } from '../inputs'
import { LessonAttemptRef, LessonResultRef } from '../types/objects'

builder.mutationField('startLesson', (t) =>
  t.field({
    type: LessonAttemptRef,
    authScopes: { authenticated: true },
    args: {
      lessonId: t.arg.string({ required: true }),
    },
    resolve: async (_root, { lessonId }, ctx) => {
      const lesson = await ctx.db.query.lessons.findFirst({
        where: eq(lessons.id, lessonId),
      })
      if (!lesson) throw new NotFoundError('Lesson not found')

      const stats = await ctx.db.query.userStats.findFirst({
        where: eq(userStats.userId, ctx.user!.id),
      })
      if (stats && stats.hearts <= 0) throw new ForbiddenError('Out of hearts')

      const [attempt] = await ctx.db
        .insert(lessonAttempts)
        .values({ userId: ctx.user!.id, lessonId, maxHearts: stats?.hearts ?? 5 })
        .returning()

      if (!attempt) throw new ValidationError('Could not start lesson')

      const exerciseRows = await ctx.db.query.exercises.findMany({
        where: eq(exercises.lessonId, lessonId),
        orderBy: (table, { asc }) => [asc(table.position)],
      })

      return {
        id: attempt.id,
        lessonId,
        startedAt: attempt.startedAt,
        maxHearts: attempt.maxHearts,
        exercises: exerciseRows,
      }
    },
  }),
)

builder.mutationField('completeLesson', (t) =>
  t.field({
    type: LessonResultRef,
    authScopes: { authenticated: true },
    args: {
      attemptId: t.arg.string({ required: true }),
      log: t.arg({ type: [ExerciseResultInput], required: true }),
    },
    resolve: async (_root, { attemptId, log }, ctx) => {
      return ctx.db.transaction(async (tx) => {
        const attempt = await tx.query.lessonAttempts.findFirst({
          where: and(eq(lessonAttempts.id, attemptId), eq(lessonAttempts.userId, ctx.user!.id)),
        })
        if (!attempt) throw new NotFoundError('Attempt not found')
        if (attempt.completedAt) throw new ValidationError('Attempt already completed')

        const lesson = await tx.query.lessons.findFirst({
          where: eq(lessons.id, attempt.lessonId),
        })
        if (!lesson) throw new NotFoundError('Lesson not found')

        const exerciseRows = await tx.query.exercises.findMany({
          where: eq(exercises.lessonId, attempt.lessonId),
          orderBy: (table, { asc }) => [asc(table.position)],
        })

        const validated = gradeAttempt(
          exerciseRows.map((exercise) => ({ id: exercise.id, payload: exercise.payload })),
          log as ExerciseAttemptLog[],
        )
        if (validated.hardReject) {
          throw new ValidationError('Could not save your progress, please try again')
        }

        const stats = await tx.query.userStats.findFirst({
          where: eq(userStats.userId, ctx.user!.id),
        })
        if (!stats) throw new NotFoundError('User stats not found')

        const xpEarned = computeXp(validated, lesson.xpReward)
        const streak = advanceStreak(
          { streakDays: stats.streakDays, lastActiveOn: stats.lastActiveOn },
          ctx.user!.tz,
          new Date(),
        )
        const lost = heartsLost(validated)
        const nextHearts = Math.max(0, stats.hearts - lost)

        const cardKeys = [
          ...new Set(validated.perExercise.flatMap((entry) => cardKeysFromPayload(entry.payload))),
        ]
        const existingCards =
          cardKeys.length === 0
            ? []
            : await tx.query.reviewCards.findMany({
                where: and(
                  eq(reviewCards.userId, ctx.user!.id),
                  inArray(reviewCards.cardKey, cardKeys),
                ),
              })
        const reviewUpdates = scheduleReviewsFor(
          ctx.user!.id,
          validated,
          new Map(existingCards.map((card) => [card.cardKey, card])),
          new Date(),
        )

        await tx
          .update(lessonAttempts)
          .set({
            completedAt: new Date(),
            xpEarned,
            log: validated.perExercise,
          })
          .where(eq(lessonAttempts.id, attempt.id))

        await tx
          .update(userStats)
          .set({
            xpTotal: stats.xpTotal + xpEarned,
            streakDays: streak.streakDays,
            lastActiveOn: streak.activeOn,
            hearts: nextHearts,
            heartsRefillAt:
              nextHearts < 5 && !stats.heartsRefillAt
                ? new Date(Date.now() + 60 * 60 * 1000)
                : stats.heartsRefillAt,
          })
          .where(eq(userStats.userId, ctx.user!.id))

        for (const card of reviewUpdates) {
          await tx
            .insert(reviewCards)
            .values({
              userId: card.userId,
              cardKey: card.cardKey,
              ease: Math.round(card.ease * 100),
              intervalDays: card.intervalDays,
              dueOn: card.dueOn,
            })
            .onConflictDoUpdate({
              target: [reviewCards.userId, reviewCards.cardKey],
              set: {
                ease: Math.round(card.ease * 100),
                intervalDays: card.intervalDays,
                dueOn: card.dueOn,
                updatedAt: sql`now()`,
              },
            })
        }

        return {
          xpEarned,
          newStreak: streak.streakDays,
          unlockedLessons: [],
        }
      })
    },
  }),
)

function cardKeysFromPayload(payload: { kind: string; prompt: Record<string, unknown> }): string[] {
  if (typeof payload.prompt.text === 'string') {
    return payload.prompt.text.toUpperCase().match(/[A-Z0-9.,?/=+\-]/g)?.map((char) => `char:${char}`) ?? []
  }
  if (typeof payload.prompt.character === 'string') return [`char:${payload.prompt.character}`]
  return []
}

