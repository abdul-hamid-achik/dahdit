import { eq } from 'drizzle-orm'
import { lessonAttempts, lessons, skills } from '../../db/schema'
import { computeUnlocks } from '../../domain/unlocks'
import { builder } from '../builder'
import { SkillTreeRef } from '../types/objects'

builder.queryField('skillTree', (t) =>
  t.field({
    type: SkillTreeRef,
    authScopes: { authenticated: true },
    resolve: async (_root, _args, ctx) => {
      const [skillRows, lessonRows, attemptRows] = await Promise.all([
        ctx.db.query.skills.findMany({ orderBy: (table, { asc }) => [asc(table.position)] }),
        ctx.db.query.lessons.findMany({ orderBy: (table, { asc }) => [asc(table.position)] }),
        ctx.db
          .select({
            lessonId: lessonAttempts.lessonId,
            skillId: lessons.skillId,
            log: lessonAttempts.log,
          })
          .from(lessonAttempts)
          .innerJoin(lessons, eq(lessonAttempts.lessonId, lessons.id))
          .where(eq(lessonAttempts.userId, ctx.user!.id)),
      ])

      const unlocks = computeUnlocks(
        skillRows.map((skill) => ({ id: skill.id, prereqIds: skill.prereqIds })),
        lessonRows.map((lesson) => ({
          id: lesson.id,
          skillId: lesson.skillId,
          position: lesson.position,
        })),
        attemptRows.map((attempt) => ({
          lessonId: attempt.lessonId,
          skillId: attempt.skillId,
          perfect: Array.isArray(attempt.log)
            ? attempt.log.every((entry) => Boolean((entry as { correct?: boolean }).correct))
            : false,
        })),
      )

      return {
        skills: skillRows,
        lessons: lessonRows,
        unlockedSkillIds: unlocks.unlockedSkillIds,
        unlockedLessonIds: unlocks.unlockedLessonIds,
      }
    },
  }),
)

