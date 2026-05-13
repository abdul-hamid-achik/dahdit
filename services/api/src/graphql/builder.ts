import SchemaBuilder from '@pothos/core'
import ErrorsPlugin from '@pothos/plugin-errors'
import RelayPlugin from '@pothos/plugin-relay'
import ScopeAuthPlugin from '@pothos/plugin-scope-auth'
import type { Context } from '../context'

export const builder = new SchemaBuilder<{
  Context: Context
  AuthScopes: {
    authenticated: boolean
  }
  Scalars: {
    DateTime: { Input: Date; Output: Date }
    JSON: { Input: unknown; Output: unknown }
  }
}>({
  plugins: [ErrorsPlugin, ScopeAuthPlugin, RelayPlugin],
  scopeAuth: {
    authScopes: async (ctx) => ({
      authenticated: !!ctx.user,
    }),
  },
  errors: {
    defaultTypes: [Error],
  },
})

builder.scalarType('DateTime', {
  serialize: (value) => (value instanceof Date ? value.toISOString() : value),
  parseValue: (value) => new Date(String(value)),
})

builder.scalarType('JSON', {
  serialize: (value) => value,
  parseValue: (value) => value,
})

builder.queryType({})
builder.mutationType({})

