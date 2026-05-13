import { and, eq, isNull } from 'drizzle-orm'
import { z } from 'zod'
import { generateRefreshToken, hashRefreshToken, signAccessToken } from '../../auth/jwt'
import { hashPassword, verifyPassword } from '../../auth/password'
import type { Context } from '../../context'
import { refreshTokens, users, userStats } from '../../db/schema'
import { AuthenticationError, ValidationError } from '../../lib/errors'
import { builder } from '../builder'
import { AuthPayloadRef } from '../types/objects'

const CredentialsZ = z.object({
  email: z.string().email().max(255),
  password: z.string().min(8).max(256),
})

builder.mutationField('signup', (t) =>
  t.field({
    type: AuthPayloadRef,
    args: {
      email: t.arg.string({ required: true }),
      username: t.arg.string({ required: true }),
      password: t.arg.string({ required: true }),
      tz: t.arg.string({ defaultValue: 'UTC' }),
    },
    resolve: async (_root, args, ctx) => {
      const credentials = CredentialsZ.parse({ email: args.email, password: args.password })
      const username = z.string().min(3).max(32).regex(/^[a-zA-Z0-9_]+$/).parse(args.username)
      const passwordHash = await hashPassword(credentials.password)

      const [user] = await ctx.db
        .insert(users)
        .values({
          email: credentials.email.toLowerCase(),
          username,
          passwordHash,
          tz: args.tz ?? 'UTC',
        })
        .returning()

      if (!user) throw new ValidationError('Could not create user')

      await ctx.db.insert(userStats).values({ userId: user.id })
      return issueAuthPayload(ctx, user)
    },
  }),
)

builder.mutationField('login', (t) =>
  t.field({
    type: AuthPayloadRef,
    args: {
      email: t.arg.string({ required: true }),
      password: t.arg.string({ required: true }),
    },
    resolve: async (_root, args, ctx) => {
      const credentials = CredentialsZ.parse(args)
      const user = await ctx.db.query.users.findFirst({
        where: and(eq(users.email, credentials.email.toLowerCase()), isNull(users.deletedAt)),
      })
      if (!user || !(await verifyPassword(credentials.password, user.passwordHash))) {
        throw new AuthenticationError('Invalid email or password')
      }
      return issueAuthPayload(ctx, user)
    },
  }),
)

builder.mutationField('refreshToken', (t) =>
  t.field({
    type: AuthPayloadRef,
    args: {
      refreshToken: t.arg.string({ required: true }),
    },
    resolve: async (_root, args, ctx) => {
      const tokenHash = await hashRefreshToken(args.refreshToken)
      const row = await ctx.db.query.refreshTokens.findFirst({
        where: eq(refreshTokens.tokenHash, tokenHash),
      })
      if (!row) throw new AuthenticationError('Refresh expired')

      if (row.revokedAt) {
        await ctx.db
          .update(refreshTokens)
          .set({ revokedAt: new Date() })
          .where(eq(refreshTokens.familyId, row.familyId))
        throw new AuthenticationError('Refresh expired')
      }

      if (row.expiresAt <= new Date()) throw new AuthenticationError('Refresh expired')

      const user = await ctx.db.query.users.findFirst({
        where: and(eq(users.id, row.userId), isNull(users.deletedAt)),
      })
      if (!user) throw new AuthenticationError('Refresh expired')

      await ctx.db
        .update(refreshTokens)
        .set({ revokedAt: new Date() })
        .where(eq(refreshTokens.id, row.id))

      return issueAuthPayload(ctx, user, row.familyId)
    },
  }),
)

builder.mutationField('deleteAccount', (t) =>
  t.boolean({
    authScopes: { authenticated: true },
    resolve: async (_root, _args, ctx) => {
      await ctx.db
        .update(users)
        .set({ deletedAt: new Date() })
        .where(eq(users.id, ctx.user!.id))
      await ctx.db
        .update(refreshTokens)
        .set({ revokedAt: new Date() })
        .where(eq(refreshTokens.userId, ctx.user!.id))
      return true
    },
  }),
)

async function issueAuthPayload(
  ctx: Pick<Context, 'db'>,
  user: { id: string; email: string; username: string; tz: string },
  familyId?: string,
) {
  const accessToken = await signAccessToken(user.id)
  const refreshToken = generateRefreshToken()
  await ctx.db.insert(refreshTokens).values({
    userId: user.id,
    tokenHash: await hashRefreshToken(refreshToken),
    familyId,
    expiresAt: addDays(new Date(), 30),
  })

  return {
    accessToken,
    refreshToken,
    user: {
      id: user.id,
      email: user.email,
      username: user.username,
      tz: user.tz,
    },
  }
}

function addDays(date: Date, days: number): Date {
  const next = new Date(date)
  next.setUTCDate(next.getUTCDate() + days)
  return next
}
