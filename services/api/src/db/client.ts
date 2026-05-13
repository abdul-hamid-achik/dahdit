import { drizzle } from 'drizzle-orm/postgres-js'
import postgres from 'postgres'
import { config } from '../config'
import * as schema from './schema'

export const sql = postgres(config.DATABASE_URL, {
  max: 10,
  idle_timeout: 20,
  connect_timeout: 10,
})

export const db = drizzle(sql, { schema })
export type Db = typeof db

export async function closeDb(): Promise<void> {
  await sql.end({ timeout: 5 })
}

