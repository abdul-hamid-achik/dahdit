import { cors } from 'hono/cors'
import { Hono } from 'hono'
import { secureHeaders } from 'hono/secure-headers'
import { createYoga } from 'graphql-yoga'
import { eq, sql as drizzleSql } from 'drizzle-orm'
import { config, corsOrigins } from './config'
import { buildContext } from './context'
import { db, sql } from './db/client'
import { reviewCards, users } from './db/schema'
import { schema } from './graphql'
import { logger } from './lib/logger'

const yoga = createYoga({
  schema,
  context: buildContext,
  graphqlEndpoint: '/graphql',
  graphiql: config.NODE_ENV !== 'production',
  maskedErrors: config.NODE_ENV === 'production',
})

const app = new Hono()

app.use('*', secureHeaders())
app.use(
  '*',
  cors({
    origin: (origin) => {
      if (!origin || corsOrigins.includes(origin)) return origin
      return corsOrigins[0] ?? ''
    },
    allowHeaders: ['Authorization', 'Content-Type', 'X-Request-ID'],
    allowMethods: ['GET', 'POST', 'OPTIONS'],
  }),
)

app.use('*', async (c, next) => {
  const requestId = c.req.header('x-request-id') ?? crypto.randomUUID()
  c.header('x-request-id', requestId)
  const started = performance.now()
  await next()
  logger.info({
    requestId,
    method: c.req.method,
    path: new URL(c.req.url).pathname,
    status: c.res.status,
    duration_ms: Math.round(performance.now() - started),
  })
})

app.get('/health', (c) => c.text('ok'))

app.get('/ready', async (c) => {
  await sql`select 1`
  return c.json({ ok: true })
})

app.get('/metrics', (c) => c.text('# Dahdit metrics placeholder\n'))

app.post('/__test/seed-review', async (c) => {
  if (config.NODE_ENV === 'production') return c.notFound()

  const body = (await c.req.json().catch(() => null)) as {
    username?: string
    cardKey?: string
  } | null
  const username = body?.username?.trim()
  const cardKey = body?.cardKey?.trim() || 'char:E'
  if (!username) return c.json({ error: 'username is required' }, 400)

  const user = await db.query.users.findFirst({
    where: eq(users.username, username),
  })
  if (!user || user.deletedAt) return c.json({ error: 'user not found' }, 404)

  await db
    .insert(reviewCards)
    .values({
      userId: user.id,
      cardKey,
      ease: 250,
      intervalDays: 0,
      dueOn: '2000-01-01',
    })
    .onConflictDoUpdate({
      target: [reviewCards.userId, reviewCards.cardKey],
      set: {
        ease: 250,
        intervalDays: 0,
        dueOn: '2000-01-01',
        updatedAt: drizzleSql`now()`,
      },
    })

  return c.json({ ok: true, userId: user.id, cardKey })
})

app.all('/graphql', (c) => yoga.fetch(c.req.raw))

export default {
  port: config.API_PORT,
  fetch: app.fetch,
}
