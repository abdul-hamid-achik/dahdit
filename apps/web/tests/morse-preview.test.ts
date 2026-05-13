import { describe, expect, test } from 'vitest'
import { encodeMorse, symbolsToCode } from '@dahdit/morse-core'

describe('web Morse preview', () => {
  test('renders code for SOS', () => {
    expect(symbolsToCode(encodeMorse('SOS'))).toBe('... --- ...')
  })
})

