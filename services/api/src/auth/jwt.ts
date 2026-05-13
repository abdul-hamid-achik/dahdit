import { sign, verify } from 'hono/jwt'
import { config } from '../config'

const accessTtlSeconds = 15 * 60

export interface AccessTokenPayload {
  sub: string
  iat: number
  exp: number
}

export async function signAccessToken(userId: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  return sign(
    {
      sub: userId,
      iat: now,
      exp: now + accessTtlSeconds,
    },
    config.JWT_SECRET,
  )
}

export async function verifyAccessToken(token: string): Promise<AccessTokenPayload | null> {
  try {
    const payload = await verify(token, config.JWT_SECRET, 'HS256')
    if (typeof payload.sub !== 'string') return null
    return payload as unknown as AccessTokenPayload
  } catch {
    return null
  }
}

export function generateRefreshToken(): string {
  return crypto.randomUUID() + '.' + crypto.randomUUID() + '.' + crypto.randomUUID()
}

export async function hashRefreshToken(token: string): Promise<string> {
  const data = new TextEncoder().encode(token)
  const digest = await crypto.subtle.digest('SHA-256', data)
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, '0')).join('')
}
