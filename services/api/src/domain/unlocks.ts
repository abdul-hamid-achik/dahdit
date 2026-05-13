export interface SkillNode {
  id: string
  prereqIds: string[]
}

export interface LessonNode {
  id: string
  skillId: string
  position: number
}

export interface CompletedLesson {
  lessonId: string
  skillId: string
  perfect: boolean
}

export interface UnlockResult {
  unlockedSkillIds: string[]
  unlockedLessonIds: string[]
}

export function computeUnlocks(
  skills: SkillNode[],
  lessons: LessonNode[],
  completed: CompletedLesson[],
): UnlockResult {
  const perfectSkillIds = new Set(completed.filter((item) => item.perfect).map((item) => item.skillId))
  const completedLessonIds = new Set(completed.map((item) => item.lessonId))
  const unlockedSkillIds = new Set<string>()

  let changed = true
  while (changed) {
    changed = false
    for (const skill of skills) {
      if (unlockedSkillIds.has(skill.id)) continue
      const prereqsMet = skill.prereqIds.every(
        (id) => perfectSkillIds.has(id) || unlockedSkillIds.has(id),
      )
      if (prereqsMet) {
        unlockedSkillIds.add(skill.id)
        changed = true
      }
    }
  }

  const unlockedLessonIds = lessons
    .filter((lesson) => unlockedSkillIds.has(lesson.skillId))
    .filter((lesson) => {
      if (lesson.position === 0) return true
      const previous = lessons.find(
        (candidate) =>
          candidate.skillId === lesson.skillId && candidate.position === lesson.position - 1,
      )
      return previous ? completedLessonIds.has(previous.id) : true
    })
    .map((lesson) => lesson.id)

  return {
    unlockedSkillIds: [...unlockedSkillIds],
    unlockedLessonIds,
  }
}

