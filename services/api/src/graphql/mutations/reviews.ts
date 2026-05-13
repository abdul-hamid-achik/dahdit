import { and, eq, inArray, lte, sql } from 'drizzle-orm'
import { scheduleNext, type ReviewGrade } from '@dahdit/morse-core'
import { reviewCards } from '../../db/schema'
import { dateInTimeZone } from '../../domain/streak'
import { ValidationError } from '../../lib/errors'
import { builder } from '../builder'
import { ReviewResultInput } from '../inputs'

const reviewGrades = new Set<ReviewGrade>(['again', 'hard', 'good', 'easy'])

interface CompleteReviewsResultObject {
  completedCount: number
  remainingDueCount: number
}

const CompleteReviewsResultRef = builder.objectRef<CompleteReviewsResultObject>('CompleteReviewsResult').implement({
  fields: (t) => ({
    completedCount: t.exposeInt('completedCount'),
    remainingDueCount: t.exposeInt('remainingDueCount'),
  }),
})

builder.mutationField('completeReviews', (t) =>
  t.field({
    type: CompleteReviewsResultRef,
    authScopes: { authenticated: true },
    args: {
      results: t.arg({ type: [ReviewResultInput], required: true }),
    },
    resolve: async (_root, { results }, ctx) => {
      if (results.length === 0) throw new ValidationError('No review results submitted')
      if (results.length > 30) throw new ValidationError('Review sessions are capped at 30 cards')

      const today = dateInTimeZone(new Date(), ctx.user!.tz)
      const gradesByCard = new Map<string, ReviewGrade>()
      for (const result of results) {
        if (!reviewGrades.has(result.grade as ReviewGrade)) {
          throw new ValidationError(`Invalid review grade: ${result.grade}`)
        }
        gradesByCard.set(result.cardKey, result.grade as ReviewGrade)
      }

      const cardKeys = [...gradesByCard.keys()]
      const rows = await ctx.db.query.reviewCards.findMany({
        where: and(
          eq(reviewCards.userId, ctx.user!.id),
          inArray(reviewCards.cardKey, cardKeys),
          lte(reviewCards.dueOn, today),
        ),
      })

      if (rows.length !== cardKeys.length) {
        throw new ValidationError('Review cards must exist and be due')
      }

      await ctx.db.transaction(async (tx) => {
        for (const row of rows) {
          const next = scheduleNext(
            {
              userId: row.userId,
              cardKey: row.cardKey as `char:${string}` | `prosign:${string}` | `word:${string}`,
              ease: row.ease / 100,
              intervalDays: row.intervalDays,
              dueOn: row.dueOn,
            },
            gradesByCard.get(row.cardKey)!,
            new Date(),
          )

          await tx
            .update(reviewCards)
            .set({
              ease: Math.round(next.ease * 100),
              intervalDays: next.intervalDays,
              dueOn: next.dueOn,
              updatedAt: sql`now()`,
            })
            .where(and(eq(reviewCards.userId, row.userId), eq(reviewCards.cardKey, row.cardKey)))
        }
      })

      const remaining = await ctx.db.query.reviewCards.findMany({
        where: and(eq(reviewCards.userId, ctx.user!.id), lte(reviewCards.dueOn, today)),
        limit: 31,
      })

      return {
        completedCount: rows.length,
        remainingDueCount: remaining.length,
      }
    },
  }),
)
