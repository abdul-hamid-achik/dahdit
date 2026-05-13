import { eq } from 'drizzle-orm'
import { userStats } from '../../db/schema'
import { builder } from '../builder'

export interface UserObject {
  id: string
  email: string
  username: string
  tz: string
}

export interface UserStatsObject {
  xpTotal: number
  streakDays: number
  hearts: number
  heartsRefillAt: Date | null
}

export interface AuthPayloadObject {
  accessToken: string
  refreshToken: string
  user: UserObject
}

export interface SkillObject {
  id: string
  slug: string
  title: string
  description: string
  position: number
  prereqIds: string[]
}

export interface LessonObject {
  id: string
  skillId: string
  slug: string
  title: string
  position: number
  xpReward: number
}

export interface ExerciseObject {
  id: string
  lessonId: string
  kind: string
  position: number
  payload: unknown
}

export interface LessonAttemptObject {
  id: string
  lessonId: string
  startedAt: Date
  maxHearts: number
  exercises: ExerciseObject[]
}

export interface LessonResultObject {
  xpEarned: number
  newStreak: number
  unlockedLessons: string[]
}

export interface SkillTreeObject {
  skills: SkillObject[]
  lessons: LessonObject[]
  unlockedSkillIds: string[]
  unlockedLessonIds: string[]
}

export interface LeaderboardEntryObject {
  userId: string
  username: string
  xpTotal: number
  streakDays: number
  rank: number
}

export interface ReviewCardObject {
  cardKey: string
  ease: number
  intervalDays: number
  dueOn: string
}

export const UserStatsRef = builder.objectRef<UserStatsObject>('UserStats').implement({
  fields: (t) => ({
    xpTotal: t.exposeInt('xpTotal'),
    streakDays: t.exposeInt('streakDays'),
    hearts: t.exposeInt('hearts'),
    heartsRefillAt: t.field({
      type: 'DateTime',
      nullable: true,
      resolve: (parent) => parent.heartsRefillAt,
    }),
  }),
})

export const UserRef = builder.objectRef<UserObject>('User').implement({
  fields: (t) => ({
    id: t.exposeString('id'),
    email: t.exposeString('email'),
    username: t.exposeString('username'),
    tz: t.exposeString('tz'),
    stats: t.field({
      type: UserStatsRef,
      resolve: async (parent, _args, ctx) => {
        const stats = await ctx.db.query.userStats.findFirst({
          where: eq(userStats.userId, parent.id),
        })

        return {
          xpTotal: stats?.xpTotal ?? 0,
          streakDays: stats?.streakDays ?? 0,
          hearts: stats?.hearts ?? 5,
          heartsRefillAt: stats?.heartsRefillAt ?? null,
        }
      },
    }),
  }),
})

export const AuthPayloadRef = builder.objectRef<AuthPayloadObject>('AuthPayload').implement({
  fields: (t) => ({
    accessToken: t.exposeString('accessToken'),
    refreshToken: t.exposeString('refreshToken'),
    user: t.field({ type: UserRef, resolve: (parent) => parent.user }),
  }),
})

export const SkillRef = builder.objectRef<SkillObject>('Skill').implement({
  fields: (t) => ({
    id: t.exposeString('id'),
    slug: t.exposeString('slug'),
    title: t.exposeString('title'),
    description: t.exposeString('description'),
    position: t.exposeInt('position'),
    prereqIds: t.field({ type: ['String'], resolve: (parent) => parent.prereqIds }),
  }),
})

export const LessonRef = builder.objectRef<LessonObject>('Lesson').implement({
  fields: (t) => ({
    id: t.exposeString('id'),
    skillId: t.exposeString('skillId'),
    slug: t.exposeString('slug'),
    title: t.exposeString('title'),
    position: t.exposeInt('position'),
    xpReward: t.exposeInt('xpReward'),
  }),
})

export const ExerciseRef = builder.objectRef<ExerciseObject>('Exercise').implement({
  fields: (t) => ({
    id: t.exposeString('id'),
    lessonId: t.exposeString('lessonId'),
    kind: t.exposeString('kind'),
    position: t.exposeInt('position'),
    payload: t.field({ type: 'JSON', resolve: (parent) => parent.payload }),
  }),
})

export const LessonAttemptRef = builder.objectRef<LessonAttemptObject>('LessonAttempt').implement({
  fields: (t) => ({
    id: t.exposeString('id'),
    lessonId: t.exposeString('lessonId'),
    startedAt: t.field({ type: 'DateTime', resolve: (parent) => parent.startedAt }),
    maxHearts: t.exposeInt('maxHearts'),
    exercises: t.field({ type: [ExerciseRef], resolve: (parent) => parent.exercises }),
  }),
})

export const LessonResultRef = builder.objectRef<LessonResultObject>('LessonResult').implement({
  fields: (t) => ({
    xpEarned: t.exposeInt('xpEarned'),
    newStreak: t.exposeInt('newStreak'),
    unlockedLessons: t.field({ type: ['String'], resolve: (parent) => parent.unlockedLessons }),
  }),
})

export const SkillTreeRef = builder.objectRef<SkillTreeObject>('SkillTree').implement({
  fields: (t) => ({
    skills: t.field({ type: [SkillRef], resolve: (parent) => parent.skills }),
    lessons: t.field({ type: [LessonRef], resolve: (parent) => parent.lessons }),
    unlockedSkillIds: t.field({ type: ['String'], resolve: (parent) => parent.unlockedSkillIds }),
    unlockedLessonIds: t.field({ type: ['String'], resolve: (parent) => parent.unlockedLessonIds }),
  }),
})

export const LeaderboardEntryRef = builder
  .objectRef<LeaderboardEntryObject>('LeaderboardEntry')
  .implement({
    fields: (t) => ({
      userId: t.exposeString('userId'),
      username: t.exposeString('username'),
      xpTotal: t.exposeInt('xpTotal'),
      streakDays: t.exposeInt('streakDays'),
      rank: t.exposeInt('rank'),
    }),
  })

export const ReviewCardRef = builder.objectRef<ReviewCardObject>('ReviewCard').implement({
  fields: (t) => ({
    cardKey: t.exposeString('cardKey'),
    ease: t.exposeFloat('ease'),
    intervalDays: t.exposeInt('intervalDays'),
    dueOn: t.exposeString('dueOn'),
  }),
})
