import { and, asc, eq, lte } from 'drizzle-orm'
import { reviewCards } from '../../db/schema'
import { dateInTimeZone } from '../../domain/streak'
import { builder } from '../builder'
import { ReviewCardRef } from '../types/objects'

builder.queryField('dueReviews', (t) =>
  t.field({
    type: [ReviewCardRef],
    authScopes: { authenticated: true },
    args: {
      limit: t.arg.int({ defaultValue: 30 }),
    },
    resolve: async (_root, { limit }, ctx) => {
      const today = dateInTimeZone(new Date(), ctx.user!.tz)
      const cappedLimit = Math.min(Math.max(limit ?? 30, 1), 30)
      const rows = await ctx.db.query.reviewCards.findMany({
        where: and(eq(reviewCards.userId, ctx.user!.id), lte(reviewCards.dueOn, today)),
        orderBy: [asc(reviewCards.dueOn), asc(reviewCards.cardKey)],
        limit: cappedLimit,
      })

      return rows.map((row) => ({
        cardKey: row.cardKey,
        ease: row.ease / 100,
        intervalDays: row.intervalDays,
        dueOn: row.dueOn,
      }))
    },
  }),
)
