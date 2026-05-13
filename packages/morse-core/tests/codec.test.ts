import { describe, expect, test } from 'bun:test'
import vectors from '../test-vectors/codec.json'
import { decodeMorse, encodeMorse, type MorseSymbol } from '../src'

describe('International Morse codec', () => {
  for (const vector of vectors) {
    test(`encodes ${vector.text}`, () => {
      expect(encodeMorse(vector.text)).toEqual(vector.symbols as MorseSymbol[])
    })

    test(`decodes ${vector.text}`, () => {
      expect(decodeMorse(vector.symbols as never)).toBe(vector.decoded)
    })
  }
})
