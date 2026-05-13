import { and, eq, isNull } from 'drizzle-orm'
import type { YogaInitialContext } from 'graphql-yoga'
import { verifyAccessToken } from './auth/jwt'
import { db, type Db } from './db/client'
import { users } from './db/schema'

export interface AuthUser {
  id: string
  email: string
  username: string
  tz: string
}

export interface Context {
  db: Db
  user: AuthUser | null
  requestId: string
}

export async function buildContext(initial: YogaInitialContext): Promise<Context> {
  const request = initial.request
  const requestId = request.headers.get('x-request-id') ?? crypto.randomUUID()
  const header = request.headers.get('authorization')
  const token = header?.startsWith('Bearer ') ? header.slice('Bearer '.length) : null
  const payload = token ? await verifyAccessToken(token) : null

  if (!payload) return { db, user: null, requestId }

  const row = await db.query.users.findFirst({
    where: and(eq(users.id, payload.sub), isNull(users.deletedAt)),
  })

  return {
    db,
    user: row
      ? {
          id: row.id,
          email: row.email,
          username: row.username,
          tz: row.tz,
        }
      : null,
    requestId,
  }
}
