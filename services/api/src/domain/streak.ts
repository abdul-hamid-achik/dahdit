export function advanceStreak(
  previous: { streakDays: number; lastActiveOn: string | null },
  userTimeZone: string,
  now: Date,
): { streakDays: number; activeOn: string } {
  const today = dateInTimeZone(now, userTimeZone)
  if (!previous.lastActiveOn) return { streakDays: 1, activeOn: today }
  if (previous.lastActiveOn === today) return { streakDays: previous.streakDays, activeOn: today }

  const yesterday = addDays(today, -1)
  if (previous.lastActiveOn === yesterday) {
    return { streakDays: previous.streakDays + 1, activeOn: today }
  }

  return { streakDays: 1, activeOn: today }
}

export function dateInTimeZone(date: Date, timeZone: string): string {
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  })
  const parts = Object.fromEntries(formatter.formatToParts(date).map((part) => [part.type, part.value]))
  return `${parts.year}-${parts.month}-${parts.day}`
}

function addDays(isoDate: string, days: number): string {
  const date = new Date(`${isoDate}T00:00:00.000Z`)
  date.setUTCDate(date.getUTCDate() + days)
  return date.toISOString().slice(0, 10)
}
