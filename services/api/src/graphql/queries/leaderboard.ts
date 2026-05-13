import { desc, eq } from 'drizzle-orm'
import { users, userStats } from '../../db/schema'
import { builder } from '../builder'
import { LeaderboardEntryRef } from '../types/objects'

builder.queryField('leaderboard', (t) =>
  t.field({
    type: [LeaderboardEntryRef],
    authScopes: { authenticated: true },
    args: {
      limit: t.arg.int({ defaultValue: 50 }),
    },
    resolve: async (_root, { limit }, ctx) => {
      const rows = await ctx.db
        .select({
          userId: userStats.userId,
          username: users.username,
          xpTotal: userStats.xpTotal,
          streakDays: userStats.streakDays,
        })
        .from(userStats)
        .innerJoin(users, eq(userStats.userId, users.id))
        .orderBy(desc(userStats.xpTotal))
        .limit(Math.min(Math.max(limit ?? 50, 1), 100))

      return rows.map((row, index) => ({ ...row, rank: index + 1 }))
    },
  }),
)

