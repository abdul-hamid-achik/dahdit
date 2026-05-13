import { writeFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { printSchema } from 'graphql'

const here = dirname(fileURLToPath(import.meta.url))
const root = resolve(here, '../../..')
const output = resolve(root, 'packages/shared-types/schema.graphqls')
process.env.DATABASE_URL ??= 'postgres://dahdit:dahdit@localhost:5432/dahdit'
process.env.JWT_SECRET ??= 'dev-only-jwt-secret-min-32-chars-long-x'

const { schema } = await import('../src/graphql')

writeFileSync(output, printSchema(schema) + '\n')
writeFileSync(resolve(root, 'apps/ios/schema.graphqls'), printSchema(schema) + '\n')

console.log(`Wrote ${output}`)
