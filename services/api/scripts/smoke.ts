import { parseExercisePayload, type ExercisePayload } from '@dahdit/morse-core'
import postgres from 'postgres'

type GraphQLError = {
  message: string
}

type GraphQLResponse<T> = {
  data?: T
  errors?: GraphQLError[]
}

type AuthPayload = {
  accessToken: string
  refreshToken: string
  user: {
    id: string
    email: string
    username: string
    tz: string
  }
}

type SkillTreeResponse = {
  skillTree: {
    unlockedLessonIds: string[]
    lessons: Array<{
      id: string
      title: string
      position: number
    }>
  }
}

type StartLessonResponse = {
  startLesson: {
    id: string
    lessonId: string
    exercises: Array<{
      id: string
      kind: string
      payload: unknown
    }>
  }
}

type CompleteLessonResponse = {
  completeLesson: {
    xpEarned: number
    newStreak: number
    unlockedLessons: string[]
  }
}

type LeaderboardResponse = {
  leaderboard: Array<{
    rank: number
    username: string
    xpTotal: number
  }>
}

type DueReviewsResponse = {
  dueReviews: Array<{
    cardKey: string
    ease: number
    intervalDays: number
    dueOn: string
  }>
}

type CompleteReviewsResponse = {
  completeReviews: {
    completedCount: number
    remainingDueCount: number
  }
}

type MeResponse = {
  me: {
    id: string
    username: string
    stats: {
      xpTotal: number
      streakDays: number
      hearts: number
    }
  } | null
}

type DeleteAccountResponse = {
  deleteAccount: boolean
}

const apiUrl = process.env.API_URL ?? process.env.SMOKE_API_URL ?? 'http://localhost:4000/graphql'
const baseUrl = new URL(apiUrl)
baseUrl.pathname = ''
baseUrl.search = ''
baseUrl.hash = ''

if (process.argv.includes('--help') || process.argv.includes('-h')) {
  console.log(`Usage: API_URL=http://localhost:4000/graphql bun scripts/smoke.ts

Runs a local API smoke test:
  - GET /health
  - GET /ready
  - signup
  - login
  - refresh token rotation and reuse rejection
  - skillTree
  - startLesson
  - completeLesson
  - me.stats
  - dueReviews
  - completeReviews
  - leaderboard
  - deleteAccount
`)
  process.exit(0)
}

await main()

async function main(): Promise<void> {
  step(`Using ${apiUrl}`)
  await assertText(`${baseUrl}health`, 'ok')
  await assertJson(`${baseUrl}ready`)

  const stamp = Date.now().toString(36)
  const email = `smoke+${stamp}@dahdit.dev`
  const username = `smoke_${stamp}`
  const password = 'smoke-password-123'

  const auth = await graphql<{ signup: AuthPayload }>(
    `mutation Signup($email: String!, $username: String!, $password: String!, $tz: String) {
      signup(email: $email, username: $username, password: $password, tz: $tz) {
        accessToken
        refreshToken
        user { id email username tz }
      }
    }`,
    {
      email,
      username,
      password,
      tz: 'America/Monterrey',
    },
  )
  step(`Signed up ${auth.signup.user.username}`)

  const login = await graphql<{ login: AuthPayload }>(
    `mutation Login($email: String!, $password: String!) {
      login(email: $email, password: $password) {
        accessToken
        refreshToken
        user { id email username tz }
      }
    }`,
    { email, password },
  )
  step(`Logged in ${login.login.user.username}`)

  const refreshed = await graphql<{ refreshToken: AuthPayload }>(
    `mutation RefreshToken($refreshToken: String!) {
      refreshToken(refreshToken: $refreshToken) {
        accessToken
        refreshToken
        user { id email username tz }
      }
    }`,
    { refreshToken: login.login.refreshToken },
  )
  const token = refreshed.refreshToken.accessToken
  step('Rotated refresh token')

  await expectGraphqlError(
    'reusing rotated refresh token should fail',
    () =>
      graphql<{ refreshToken: AuthPayload }>(
        `mutation RefreshToken($refreshToken: String!) {
          refreshToken(refreshToken: $refreshToken) {
            accessToken
            refreshToken
            user { id email username tz }
          }
        }`,
        { refreshToken: login.login.refreshToken },
      ),
  )
  await expectGraphqlError(
    'refresh token family should be revoked after reuse',
    () =>
      graphql<{ refreshToken: AuthPayload }>(
        `mutation RefreshToken($refreshToken: String!) {
          refreshToken(refreshToken: $refreshToken) {
            accessToken
            refreshToken
            user { id email username tz }
          }
        }`,
        { refreshToken: refreshed.refreshToken.refreshToken },
      ),
  )
  step('Rejected reused refresh token family')

  const tree = await graphql<SkillTreeResponse>(
    `query SkillTree {
      skillTree {
        unlockedLessonIds
        lessons { id title position }
      }
    }`,
    {},
    token,
  )

  if (tree.skillTree.lessons.length < 4) {
    throw new Error(
      `Expected seeded beginner skill to include at least 4 lessons, found ${tree.skillTree.lessons.length}`,
    )
  }
  step(`Loaded seeded curriculum with ${tree.skillTree.lessons.length} lessons`)

  const lesson =
    tree.skillTree.lessons.find((candidate) =>
      tree.skillTree.unlockedLessonIds.includes(candidate.id),
    ) ?? tree.skillTree.lessons[0]

  if (!lesson) {
    throw new Error('No lesson returned by skillTree. Did you run task seed?')
  }
  step(`Starting lesson "${lesson.title}"`)

  const started = await graphql<StartLessonResponse>(
    `mutation StartLesson($lessonId: String!) {
      startLesson(lessonId: $lessonId) {
        id
        lessonId
        exercises {
          id
          kind
          payload
        }
      }
    }`,
    { lessonId: lesson.id },
    token,
  )

  const log = started.startLesson.exercises.map((exercise, index) => {
    const payload = parseExercisePayload(exercise.payload)
    return {
      exerciseId: exercise.id,
      correct: true,
      timeMs: 15000 + index * 777,
      answer: answerFor(payload),
    }
  })

  const completed = await graphql<CompleteLessonResponse>(
    `mutation CompleteLesson($attemptId: String!, $log: [ExerciseResultInput!]!) {
      completeLesson(attemptId: $attemptId, log: $log) {
        xpEarned
        newStreak
        unlockedLessons
      }
    }`,
    {
      attemptId: started.startLesson.id,
      log,
    },
    token,
  )

  step(
    `Completed lesson: ${completed.completeLesson.xpEarned} XP, streak ${completed.completeLesson.newStreak}`,
  )

  const profile = await graphql<MeResponse>(
    `query Me {
      me {
        id
        username
        stats {
          xpTotal
          streakDays
          hearts
        }
      }
    }`,
    {},
    token,
  )

  if (!profile.me) throw new Error('me returned null for an authenticated user')
  if (profile.me.stats.xpTotal < completed.completeLesson.xpEarned) {
    throw new Error('me.stats did not include completed lesson XP')
  }
  step(`Profile stats show ${profile.me.stats.xpTotal} XP`)

  await seedDueReviewCard(profile.me.id)

  const dueReviews = await graphql<DueReviewsResponse>(
    `query DueReviews($limit: Int) {
      dueReviews(limit: $limit) {
        cardKey
        ease
        intervalDays
        dueOn
      }
    }`,
    { limit: 30 },
    token,
  )
  if (dueReviews.dueReviews.length === 0) {
    throw new Error('Due review queue should include the seeded review card')
  }
  step(`Due review queue has ${dueReviews.dueReviews.length} cards`)

  const reviewResult = await graphql<CompleteReviewsResponse>(
    `mutation CompleteReviews($results: [ReviewResultInput!]!) {
      completeReviews(results: $results) {
        completedCount
        remainingDueCount
      }
    }`,
    {
      results: [{ cardKey: 'char:E', grade: 'good' }],
    },
    token,
  )
  if (reviewResult.completeReviews.completedCount !== 1) {
    throw new Error('completeReviews did not complete the seeded review card')
  }
  step(`Completed ${reviewResult.completeReviews.completedCount} review card`)

  const leaderboard = await graphql<LeaderboardResponse>(
    `query Leaderboard {
      leaderboard(limit: 5) {
        rank
        username
        xpTotal
      }
    }`,
    {},
    token,
  )

  if (leaderboard.leaderboard.length === 0) {
    throw new Error('Leaderboard returned no rows')
  }

  step(`Leaderboard has ${leaderboard.leaderboard.length} rows`)

  const deleted = await graphql<DeleteAccountResponse>(
    `mutation DeleteAccount {
      deleteAccount
    }`,
    {},
    token,
  )
  if (!deleted.deleteAccount) throw new Error('deleteAccount returned false')
  step('Deleted smoke account')

  await expectGraphqlError(
    'deleted account access token should no longer authorize protected fields',
    () =>
      graphql<DueReviewsResponse>(
        `query DueReviews {
          dueReviews {
            cardKey
          }
        }`,
        {},
        token,
      ),
  )
  step('Rejected deleted account token')

  console.log('Smoke test passed')
}

function answerFor(payload: ExercisePayload): unknown {
  switch (payload.kind) {
    case 'listenAndType':
    case 'copyAtSpeed':
      return payload.solution.accept[0]
    case 'tapTheCode':
    case 'translateToMorse':
      return payload.solution.symbols
    case 'matchCharacterToCode':
      return payload.solution.correctIndex
  }
}

async function assertText(url: string, expected: string): Promise<void> {
  const response = await fetch(url)
  const text = await response.text()
  if (!response.ok || text.trim() !== expected) {
    throw new Error(`${url} expected ${expected}, got HTTP ${response.status}: ${text}`)
  }
  step(`${new URL(url).pathname} ok`)
}

async function assertJson(url: string): Promise<void> {
  const response = await fetch(url)
  const body = await response.text()
  if (!response.ok) {
    throw new Error(`${url} expected HTTP 2xx, got ${response.status}: ${body}`)
  }
  JSON.parse(body)
  step(`${new URL(url).pathname} ok`)
}

async function graphql<T>(
  query: string,
  variables: Record<string, unknown>,
  token?: string,
): Promise<T> {
  const response = await fetch(apiUrl, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify({ query, variables }),
  })

  const body = (await response.json()) as GraphQLResponse<T>
  if (!response.ok || body.errors?.length) {
    throw new Error(
      body.errors?.map((error) => error.message).join('; ') ??
        `GraphQL request failed with HTTP ${response.status}`,
    )
  }
  if (!body.data) throw new Error('GraphQL response did not include data')
  return body.data
}

async function expectGraphqlError(label: string, callback: () => Promise<unknown>): Promise<void> {
  try {
    await callback()
  } catch {
    return
  }
  throw new Error(`Expected GraphQL error: ${label}`)
}

async function seedDueReviewCard(userId: string): Promise<void> {
  const sql = postgres(
    process.env.DATABASE_URL ?? 'postgres://dahdit:dahdit@localhost:5432/dahdit',
    { max: 1 },
  )
  const dueOn = '2000-01-01'
  try {
    await sql`
      insert into review_cards (user_id, card_key, ease_basis_points, interval_days, due_on)
      values (${userId}, 'char:E', 250, 0, ${dueOn})
      on conflict (user_id, card_key)
      do update set due_on = ${dueOn}, interval_days = 0, updated_at = now()
    `
  } finally {
    await sql.end({ timeout: 5 })
  }
}

function step(message: string): void {
  console.log(`[smoke] ${message}`)
}
