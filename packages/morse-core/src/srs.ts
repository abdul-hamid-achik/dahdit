export type CardKey = `char:${string}` | `prosign:${string}` | `word:${string}`
export type ReviewGrade = 'again' | 'hard' | 'good' | 'easy'

export interface ReviewCard {
  userId: string
  cardKey: CardKey
  ease: number
  intervalDays: number
  dueOn: string
}

export function scheduleNext(card: ReviewCard, grade: ReviewGrade, today: Date): ReviewCard {
  const date = utcDateOnly(today)
  let ease = card.ease
  let intervalDays = card.intervalDays

  switch (grade) {
    case 'again':
      ease -= 0.2
      intervalDays = 1
      break
    case 'hard':
      ease -= 0.15
      intervalDays = Math.max(1, Math.ceil(intervalDays * 1.2))
      break
    case 'good':
      intervalDays = Math.max(1, Math.ceil(intervalDays * ease))
      break
    case 'easy':
      ease += 0.15
      intervalDays = Math.max(1, Math.ceil(intervalDays * ease * 1.3))
      break
  }

  const next = new Date(date)
  next.setUTCDate(next.getUTCDate() + intervalDays)

  return {
    ...card,
    ease: clamp(round2(ease), 1.3, 2.5),
    intervalDays,
    dueOn: toIsoDate(next),
  }
}

export function cardKeysForText(text: string): CardKey[] {
  const keys = new Set<CardKey>()
  for (const char of text.toUpperCase()) {
    if (/[A-Z0-9.,?/=+\-]/.test(char)) keys.add(`char:${char}`)
  }
  for (const word of text.toUpperCase().match(/[A-Z0-9]{2,}/g) ?? []) {
    if (['THE', 'AND', 'CQ', 'DE', 'SOS', 'RIG', 'NET'].includes(word)) keys.add(`word:${word}`)
  }
  return [...keys].sort()
}

export function newReviewCard(userId: string, cardKey: CardKey, today: Date): ReviewCard {
  return {
    userId,
    cardKey,
    ease: 2.5,
    intervalDays: 0,
    dueOn: toIsoDate(today),
  }
}

export function toIsoDate(date: Date): string {
  return date.toISOString().slice(0, 10)
}

function utcDateOnly(date: Date): Date {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()))
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value))
}

function round2(value: number): number {
  return Math.round(value * 100) / 100
}

