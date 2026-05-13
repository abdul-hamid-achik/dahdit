import { sql } from 'drizzle-orm'
import {
  boolean,
  customType,
  date,
  index,
  integer,
  jsonb,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core'

const citext = customType<{ data: string }>({
  dataType() {
    return 'citext'
  },
})

export const users = pgTable(
  'users',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    email: citext('email').notNull(),
    username: text('username').notNull(),
    passwordHash: text('password_hash').notNull(),
    tz: text('tz').notNull().default('UTC'),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    emailUnique: uniqueIndex('users_email_unique').on(table.email),
    usernameUnique: uniqueIndex('users_username_unique').on(table.username),
  }),
)

export const refreshTokens = pgTable(
  'refresh_tokens',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    tokenHash: text('token_hash').notNull(),
    familyId: uuid('family_id').notNull().defaultRandom(),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    revokedAt: timestamp('revoked_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    userIdx: index('refresh_tokens_user_idx').on(table.userId),
    hashUnique: uniqueIndex('refresh_tokens_hash_unique').on(table.tokenHash),
  }),
)

export const userStats = pgTable('user_stats', {
  userId: uuid('user_id')
    .primaryKey()
    .references(() => users.id, { onDelete: 'cascade' }),
  xpTotal: integer('xp_total').notNull().default(0),
  streakDays: integer('streak_days').notNull().default(0),
  lastActiveOn: date('last_active_on'),
  hearts: integer('hearts').notNull().default(5),
  heartsRefillAt: timestamp('hearts_refill_at', { withTimezone: true }),
})

export const skills = pgTable('skills', {
  id: uuid('id').primaryKey().defaultRandom(),
  slug: text('slug').notNull().unique(),
  title: text('title').notNull(),
  description: text('description').notNull().default(''),
  position: integer('position').notNull(),
  prereqIds: uuid('prereq_ids')
    .array()
    .notNull()
    .default(sql`ARRAY[]::uuid[]`),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
})

export const lessons = pgTable(
  'lessons',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    skillId: uuid('skill_id')
      .notNull()
      .references(() => skills.id, { onDelete: 'cascade' }),
    slug: text('slug').notNull(),
    title: text('title').notNull(),
    position: integer('position').notNull(),
    xpReward: integer('xp_reward').notNull().default(10),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    skillPositionUnique: uniqueIndex('lessons_skill_position_unique').on(
      table.skillId,
      table.position,
    ),
  }),
)

export const exercises = pgTable(
  'exercises',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    lessonId: uuid('lesson_id')
      .notNull()
      .references(() => lessons.id, { onDelete: 'cascade' }),
    kind: text('kind').notNull(),
    position: integer('position').notNull(),
    payload: jsonb('payload').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    lessonPositionUnique: uniqueIndex('exercises_lesson_position_unique').on(
      table.lessonId,
      table.position,
    ),
  }),
)

export const lessonAttempts = pgTable(
  'lesson_attempts',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    lessonId: uuid('lesson_id')
      .notNull()
      .references(() => lessons.id, { onDelete: 'cascade' }),
    startedAt: timestamp('started_at', { withTimezone: true }).notNull().defaultNow(),
    completedAt: timestamp('completed_at', { withTimezone: true }),
    xpEarned: integer('xp_earned').notNull().default(0),
    maxHearts: integer('max_hearts').notNull().default(5),
    log: jsonb('log').notNull().default(sql`'[]'::jsonb`),
  },
  (table) => ({
    userIdx: index('lesson_attempts_user_idx').on(table.userId),
    lessonIdx: index('lesson_attempts_lesson_idx').on(table.lessonId),
  }),
)

export const reviewCards = pgTable(
  'review_cards',
  {
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    cardKey: text('card_key').notNull(),
    ease: integer('ease_basis_points').notNull().default(250),
    intervalDays: integer('interval_days').notNull().default(0),
    dueOn: date('due_on').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    userCardUnique: uniqueIndex('review_cards_user_card_unique').on(table.userId, table.cardKey),
    dueIdx: index('review_cards_due_idx').on(table.userId, table.dueOn),
  }),
)

export const skillProgress = pgTable(
  'skill_progress',
  {
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    skillId: uuid('skill_id')
      .notNull()
      .references(() => skills.id, { onDelete: 'cascade' }),
    completed: boolean('completed').notNull().default(false),
    grandfatheredAt: timestamp('grandfathered_at', { withTimezone: true }),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    userSkillUnique: uniqueIndex('skill_progress_user_skill_unique').on(
      table.userId,
      table.skillId,
    ),
  }),
)

