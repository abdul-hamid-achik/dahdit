<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { encodeMorse, symbolsToCode, type MorseSymbol } from '@dahdit/morse-core'

type GraphQLError = { message: string }
type GraphQLResponse<T> = { data?: T; errors?: GraphQLError[] }

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

type User = AuthPayload['user'] & {
  stats: {
    xpTotal: number
    streakDays: number
    hearts: number
    heartsRefillAt: string | null
  } | null
}

type Skill = {
  id: string
  slug: string
  title: string
  description: string
  position: number
}

type Lesson = {
  id: string
  skillId: string
  slug: string
  title: string
  position: number
  xpReward: number
}

type LeaderboardEntry = {
  userId: string
  username: string
  xpTotal: number
  streakDays: number
  rank: number
}

type ReviewCard = {
  cardKey: string
  ease: number
  intervalDays: number
  dueOn: string
}

type DashboardData = {
  me: User | null
  skillTree: {
    unlockedLessonIds: string[]
    skills: Skill[]
    lessons: Lesson[]
  }
  dueReviews: ReviewCard[]
  leaderboard: LeaderboardEntry[]
}

const storageKey = 'dahdit.web.auth'
const config = useRuntimeConfig()
const selected = ref('SOS')
const choices = ['SOS', 'CQ', 'DE', 'ET']
const authMode = ref<'signup' | 'login'>('signup')
const auth = ref<AuthPayload | null>(null)
const authError = ref<string | null>(null)
const dashboardError = ref<string | null>(null)
const isSubmitting = ref(false)
const isDashboardLoading = ref(false)
const dashboard = ref<DashboardData | null>(null)

const form = reactive({
  email: '',
  username: '',
  password: '',
})

const symbols = computed(() => encodeMorse(selected.value))
const code = computed(() => symbolsToCode(symbols.value))
const isSignedIn = computed(() => Boolean(auth.value?.accessToken))
const activeUser = computed(() => dashboard.value?.me ?? auth.value?.user ?? null)
const stats = computed(() => dashboard.value?.me?.stats ?? null)
const firstSkill = computed(() => dashboard.value?.skillTree.skills[0] ?? null)
const lessons = computed(() =>
  (dashboard.value?.skillTree.lessons ?? [])
    .filter((lesson) => !firstSkill.value || lesson.skillId === firstSkill.value.id)
    .sort((left, right) => left.position - right.position),
)
const unlockedLessonIds = computed(() => new Set(dashboard.value?.skillTree.unlockedLessonIds ?? []))

onMounted(() => {
  const raw = window.localStorage.getItem(storageKey)
  if (!raw) return

  try {
    auth.value = JSON.parse(raw) as AuthPayload
    void loadDashboard()
  } catch {
    window.localStorage.removeItem(storageKey)
  }
})

function classForSymbol(symbol: MorseSymbol) {
  if (symbol === 'dit') return 'dit'
  if (symbol === 'dah') return 'dah'
  return 'gap'
}

function cardLabel(cardKey: string) {
  return cardKey
    .replace(/^char:/, '')
    .replace(/^word:/, '')
    .replace(/^prosign:/, '')
    .replace(/_/g, ' ')
}

function lessonState(lesson: Lesson) {
  if (unlockedLessonIds.value.has(lesson.id)) return 'Unlocked'
  return 'Locked'
}

async function submitAuth() {
  authError.value = null
  isSubmitting.value = true
  try {
    const operation =
      authMode.value === 'signup'
        ? `mutation Signup($email: String!, $username: String!, $password: String!, $tz: String) {
            signup(email: $email, username: $username, password: $password, tz: $tz) {
              accessToken
              refreshToken
              user { id email username tz }
            }
          }`
        : `mutation Login($email: String!, $password: String!) {
            login(email: $email, password: $password) {
              accessToken
              refreshToken
              user { id email username tz }
            }
          }`

    const variables =
      authMode.value === 'signup'
        ? {
            email: form.email,
            username: form.username,
            password: form.password,
            tz: Intl.DateTimeFormat().resolvedOptions().timeZone,
          }
        : { email: form.email, password: form.password }

    const data = await graphql<{ signup?: AuthPayload; login?: AuthPayload }>(operation, variables, null)
    const payload = authMode.value === 'signup' ? data.signup : data.login
    if (!payload) throw new Error('Authentication did not return a session')

    setAuth(payload)
    await loadDashboard()
  } catch (error) {
    authError.value = error instanceof Error ? error.message : 'Authentication failed'
  } finally {
    isSubmitting.value = false
  }
}

async function loadDashboard() {
  if (!auth.value?.accessToken) return
  dashboardError.value = null
  isDashboardLoading.value = true
  try {
    dashboard.value = await graphql<DashboardData>(
      `query WebDashboard {
        me {
          id
          email
          username
          tz
          stats {
            xpTotal
            streakDays
            hearts
            heartsRefillAt
          }
        }
        skillTree {
          unlockedLessonIds
          skills {
            id
            slug
            title
            description
            position
          }
          lessons {
            id
            skillId
            slug
            title
            position
            xpReward
          }
        }
        dueReviews(limit: 8) {
          cardKey
          ease
          intervalDays
          dueOn
        }
        leaderboard(limit: 5) {
          userId
          username
          xpTotal
          streakDays
          rank
        }
      }`,
    )
  } catch (error) {
    dashboardError.value = error instanceof Error ? error.message : 'Could not load dashboard'
  } finally {
    isDashboardLoading.value = false
  }
}

function setAuth(payload: AuthPayload) {
  auth.value = payload
  window.localStorage.setItem(storageKey, JSON.stringify(payload))
}

function signOut() {
  auth.value = null
  dashboard.value = null
  window.localStorage.removeItem(storageKey)
}

async function refreshSession() {
  if (!auth.value?.refreshToken) throw new Error('Session expired')
  const data = await graphql<{ refreshToken: AuthPayload }>(
    `mutation RefreshToken($refreshToken: String!) {
      refreshToken(refreshToken: $refreshToken) {
        accessToken
        refreshToken
        user { id email username tz }
      }
    }`,
    { refreshToken: auth.value.refreshToken },
    null,
    false,
  )
  setAuth(data.refreshToken)
}

async function graphql<T>(
  query: string,
  variables: Record<string, unknown> = {},
  token = auth.value?.accessToken ?? null,
  retryAuth = true,
): Promise<T> {
  const headers: HeadersInit = { 'content-type': 'application/json' }
  if (token) headers.authorization = `Bearer ${token}`

  const response = await fetch(config.public.graphqlUrl, {
    method: 'POST',
    headers,
    body: JSON.stringify({ query, variables }),
  })

  const result = (await response.json().catch(() => null)) as GraphQLResponse<T> | null
  const errors = result?.errors ?? []
  if (!response.ok || errors.length > 0 || !result?.data) {
    const message = errors.map((error) => error.message).join(', ') || `GraphQL request failed (${response.status})`
    if (retryAuth && auth.value?.refreshToken && /auth|token|not authorized|expired/i.test(message)) {
      await refreshSession()
      return graphql<T>(query, variables, auth.value?.accessToken ?? null, false)
    }
    throw new Error(message)
  }

  return result.data
}
</script>

<template>
  <main class="page">
    <header class="shell topbar">
      <a class="brand" href="/" aria-label="Dahdit home">
        <span class="brand-mark">.-</span>
        <span>Dahdit</span>
      </a>
      <nav class="nav" aria-label="Primary navigation">
        <a href="#trainer">Trainer</a>
        <a href="#dashboard">Dashboard</a>
        <a href="#status">Signal</a>
      </nav>
      <button v-if="isSignedIn" class="button secondary" type="button" @click="signOut">Sign out</button>
      <a v-else class="button secondary" href="#dashboard">Sign in</a>
    </header>

    <section id="trainer" class="shell hero">
      <div class="hero-copy-block">
        <h1>Dahdit</h1>
        <p class="hero-copy">
          A mobile-first Morse trainer for listening, tapping, spaced repetition, and daily operator practice.
        </p>
        <div class="hero-actions">
          <a class="button" href="#dashboard">{{ isSignedIn ? 'Open learner station' : 'Start learner station' }}</a>
          <a class="button secondary" href="http://localhost:4000/graphql">GraphQL endpoint</a>
        </div>
        <div class="metrics" aria-label="Training metrics">
          <div class="metric">
            <strong>{{ stats?.xpTotal ?? 0 }} XP</strong>
            <span>{{ isSignedIn ? 'current station log' : 'sign in to sync progress' }}</span>
          </div>
          <div class="metric">
            <strong>{{ stats?.streakDays ?? 0 }} days</strong>
            <span>active streak</span>
          </div>
          <div class="metric">
            <strong>{{ dashboard?.dueReviews.length ?? 0 }}</strong>
            <span>cards due now</span>
          </div>
        </div>
      </div>

      <div class="trainer" aria-label="Morse trainer preview">
        <div class="trainer-head">
          <strong>Listen and type</strong>
          <span class="hearts">{{ stats?.hearts ?? 5 }} hearts</span>
        </div>
        <div class="trainer-body">
          <div class="wave" aria-label="Morse waveform">
            <span v-for="(symbol, index) in symbols" :key="index" :class="classForSymbol(symbol)" />
          </div>
          <p>
            <strong>{{ selected }}</strong>
            <span>is</span>
            <code>{{ code }}</code>
          </p>
          <div class="answer-grid">
            <button
              v-for="choice in choices"
              :key="choice"
              class="answer"
              :class="{ selected: selected === choice }"
              type="button"
              @click="selected = choice"
            >
              {{ choice }}
            </button>
          </div>
        </div>
      </div>
    </section>

    <section id="dashboard" class="shell dashboard">
      <aside class="panel auth-panel">
        <div class="panel-title">
          <span>Station access</span>
          <strong>{{ activeUser?.username ?? 'Guest operator' }}</strong>
        </div>

        <div v-if="isSignedIn" class="station-card">
          <div>
            <span class="muted-label">Signed in as</span>
            <strong>{{ activeUser?.email }}</strong>
          </div>
          <button class="button secondary full" type="button" :disabled="isDashboardLoading" @click="loadDashboard">
            {{ isDashboardLoading ? 'Tuning...' : 'Refresh station' }}
          </button>
        </div>

        <form v-else class="auth-form" @submit.prevent="submitAuth">
          <div class="mode-toggle" aria-label="Authentication mode">
            <button
              type="button"
              :class="{ active: authMode === 'signup' }"
              @click="authMode = 'signup'"
            >
              Sign up
            </button>
            <button
              type="button"
              :class="{ active: authMode === 'login' }"
              @click="authMode = 'login'"
            >
              Log in
            </button>
          </div>
          <label>
            Email
            <input v-model="form.email" autocomplete="email" required type="email" />
          </label>
          <label v-if="authMode === 'signup'">
            Username
            <input v-model="form.username" autocomplete="username" maxlength="32" minlength="3" required />
          </label>
          <label>
            Password
            <input v-model="form.password" autocomplete="current-password" minlength="8" required type="password" />
          </label>
          <p v-if="authError" class="error">{{ authError }}</p>
          <button class="button full" type="submit" :disabled="isSubmitting">
            {{ isSubmitting ? 'Calling...' : authMode === 'signup' ? 'Create station' : 'Open station' }}
          </button>
        </form>
      </aside>

      <div class="dashboard-stack">
        <div v-if="dashboardError" class="panel error-panel">
          <strong>Could not load learner data</strong>
          <span>{{ dashboardError }}</span>
        </div>

        <div class="stats-grid">
          <div class="panel stat-panel">
            <span>XP total</span>
            <strong>{{ stats?.xpTotal ?? 0 }}</strong>
          </div>
          <div class="panel stat-panel">
            <span>Streak</span>
            <strong>{{ stats?.streakDays ?? 0 }}d</strong>
          </div>
          <div class="panel stat-panel">
            <span>Reviews</span>
            <strong>{{ dashboard?.dueReviews.length ?? 0 }}</strong>
          </div>
        </div>

        <div class="panel skill-panel">
          <div class="panel-title row-title">
            <span>{{ firstSkill?.title ?? 'Foundations' }}</span>
            <strong>{{ lessons.length || 4 }} lessons</strong>
          </div>
          <div class="lesson-list">
            <div v-for="lesson in lessons" :key="lesson.id" class="lesson-row">
              <span class="lesson-index">{{ lesson.position + 1 }}</span>
              <div>
                <strong>{{ lesson.title }}</strong>
                <span>{{ lesson.xpReward }} XP reward</span>
              </div>
              <em :class="{ unlocked: unlockedLessonIds.has(lesson.id) }">{{ lessonState(lesson) }}</em>
            </div>
            <div v-if="!lessons.length" class="empty-row">
              Sign in to load the seeded Foundations lesson path.
            </div>
          </div>
        </div>

        <div class="two-column">
          <div class="panel">
            <div class="panel-title row-title">
              <span>Due review</span>
              <strong>{{ dashboard?.dueReviews.length ?? 0 }} cards</strong>
            </div>
            <div class="review-list">
              <div v-for="card in dashboard?.dueReviews ?? []" :key="card.cardKey" class="review-row">
                <strong>{{ cardLabel(card.cardKey) }}</strong>
                <span>Due {{ card.dueOn }} · ease {{ card.ease.toFixed(2) }}</span>
              </div>
              <div v-if="!dashboard?.dueReviews.length" class="empty-row">
                No due cards loaded. Complete a lesson in the iOS app to seed SRS.
              </div>
            </div>
          </div>

          <div id="status" class="panel">
            <div class="panel-title row-title">
              <span>Leaderboard</span>
              <strong>Top {{ dashboard?.leaderboard.length ?? 0 }}</strong>
            </div>
            <div class="leaderboard-list">
              <div v-for="entry in dashboard?.leaderboard ?? []" :key="entry.userId" class="leaderboard-row">
                <strong>#{{ entry.rank }}</strong>
                <span>{{ entry.username }}</span>
                <em>{{ entry.xpTotal }} XP</em>
              </div>
              <div v-if="!dashboard?.leaderboard.length" class="empty-row">
                Sign in to tune the leaderboard.
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  </main>
</template>
