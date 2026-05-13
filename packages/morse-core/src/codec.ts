export type MorseSymbol = 'dit' | 'dah' | 'charGap' | 'wordGap'

export interface MorseTiming {
  wpm: number
  farnsworthWpm?: number | undefined
  toneHz?: number | undefined
}

export const INTERNATIONAL_MORSE: Readonly<Record<string, string>> = Object.freeze({
  A: '.-',
  B: '-...',
  C: '-.-.',
  D: '-..',
  E: '.',
  F: '..-.',
  G: '--.',
  H: '....',
  I: '..',
  J: '.---',
  K: '-.-',
  L: '.-..',
  M: '--',
  N: '-.',
  O: '---',
  P: '.--.',
  Q: '--.-',
  R: '.-.',
  S: '...',
  T: '-',
  U: '..-',
  V: '...-',
  W: '.--',
  X: '-..-',
  Y: '-.--',
  Z: '--..',
  '0': '-----',
  '1': '.----',
  '2': '..---',
  '3': '...--',
  '4': '....-',
  '5': '.....',
  '6': '-....',
  '7': '--...',
  '8': '---..',
  '9': '----.',
  '.': '.-.-.-',
  ',': '--..--',
  '?': '..--..',
  '/': '-..-.',
  '=': '-...-',
  '+': '.-.-.',
  '-': '-....-',
})

const MORSE_TO_TEXT = new Map(Object.entries(INTERNATIONAL_MORSE).map(([char, code]) => [code, char]))

export function unitMs(timing: Pick<MorseTiming, 'wpm'>): number {
  return 1200 / timing.wpm
}

export function encodeMorse(text: string): MorseSymbol[] {
  const words = text
    .trim()
    .toUpperCase()
    .split(/\s+/)
    .filter(Boolean)

  const symbols: MorseSymbol[] = []
  words.forEach((word, wordIndex) => {
    const chars = [...word].filter((char) => INTERNATIONAL_MORSE[char])
    chars.forEach((char, charIndex) => {
      const code = INTERNATIONAL_MORSE[char]
      if (!code) return
      for (const mark of code) symbols.push(mark === '.' ? 'dit' : 'dah')
      if (charIndex < chars.length - 1) symbols.push('charGap')
    })
    if (wordIndex < words.length - 1) symbols.push('wordGap')
  })
  return symbols
}

export function symbolsToCode(symbols: MorseSymbol[]): string {
  return symbols
    .map((symbol) => {
      if (symbol === 'dit') return '.'
      if (symbol === 'dah') return '-'
      if (symbol === 'charGap') return ' '
      return ' / '
    })
    .join('')
    .replace(/\s+/g, ' ')
    .trim()
}

export function decodeMorse(symbols: MorseSymbol[]): string {
  const words: string[] = []
  let word = ''
  let current = ''

  const flushChar = () => {
    if (!current) return
    word += MORSE_TO_TEXT.get(current) ?? '?'
    current = ''
  }

  for (const symbol of symbols) {
    if (symbol === 'dit' || symbol === 'dah') {
      current += symbol === 'dit' ? '.' : '-'
      continue
    }

    flushChar()
    if (symbol === 'wordGap') {
      if (word) words.push(word)
      word = ''
    }
  }

  flushChar()
  if (word) words.push(word)
  return words.join(' ')
}

export function audioDurationMs(symbols: MorseSymbol[], timing: MorseTiming): number {
  const unit = unitMs(timing)
  let totalUnits = 0

  symbols.forEach((symbol, index) => {
    if (symbol === 'dit') totalUnits += 1
    if (symbol === 'dah') totalUnits += 3
    if (symbol === 'charGap') totalUnits += charGapUnits(timing)
    if (symbol === 'wordGap') totalUnits += wordGapUnits(timing)

    const next = symbols[index + 1]
    if ((symbol === 'dit' || symbol === 'dah') && (next === 'dit' || next === 'dah')) {
      totalUnits += 1
    }
  })

  return totalUnits * unit
}

export function charGapUnits(timing: MorseTiming): number {
  return stretchedGapUnits(timing, 3)
}

export function wordGapUnits(timing: MorseTiming): number {
  return stretchedGapUnits(timing, 7)
}

function stretchedGapUnits(timing: MorseTiming, standardUnits: number): number {
  if (!timing.farnsworthWpm || timing.farnsworthWpm >= timing.wpm) return standardUnits
  return standardUnits * (timing.wpm / timing.farnsworthWpm)
}
