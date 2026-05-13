import type { CodegenConfig } from '@graphql-codegen/cli'

const config: CodegenConfig = {
  schema: './schema.graphqls',
  documents: './operations/**/*.graphql',
  generates: {
    './src/generated.ts': {
      plugins: ['typescript', 'typescript-operations'],
      config: {
        avoidOptionals: true,
        immutableTypes: true,
        scalars: {
          DateTime: 'string',
          JSON: 'unknown',
        },
      },
    },
  },
}

export default config

