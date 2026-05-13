import type { MorseSymbol, MorseTiming } from './codec'
import { unitMs } from './codec'

export type SendBoundary = 'sameCharacter' | 'characterBoundary' | 'endOfInput'

export interface SendTimingEvent {
  keyDownAtMs: number
  keyUpAtMs: number
}

export interface SendDecodeResult {
  symbols: MorseSymbol[]
  boundaries: SendBoundary[]
}

export function classifyPress(durationMs: number, timing: MorseTiming): 'dit' | 'dah' {
  return durationMs < 1.5 * unitMs(timing) ? 'dit' : 'dah'
}

export function classifyGap(gapMs: number, timing: MorseTiming): SendBoundary {
  const unit = unitMs(timing)
  if (gapMs < 1.5 * unit) return 'sameCharacter'
  if (gapMs < 5 * unit) return 'characterBoundary'
  return 'endOfInput'
}

export function decodeSendEvents(events: SendTimingEvent[], timing: MorseTiming): SendDecodeResult {
  const symbols: MorseSymbol[] = []
  const boundaries: SendBoundary[] = []

  events.forEach((event, index) => {
    symbols.push(classifyPress(event.keyUpAtMs - event.keyDownAtMs, timing))
    const next = events[index + 1]
    if (!next) return

    const boundary = classifyGap(next.keyDownAtMs - event.keyUpAtMs, timing)
    boundaries.push(boundary)
    if (boundary === 'characterBoundary') symbols.push('charGap')
    if (boundary === 'endOfInput') symbols.push('wordGap')
  })

  return { symbols, boundaries }
}

