import type { PluginOption } from 'vite'

const voidModuleName = 'void'
const voidModule = (await import(voidModuleName).catch(() => null)) as
  | { voidPlugin?: () => PluginOption }
  | null

export default defineNuxtConfig({
  compatibilityDate: '2026-05-11',
  modules: ['@nuxt/ui'],
  css: ['~/assets/css/main.css'],
  runtimeConfig: {
    public: {
      graphqlUrl: process.env.WEB_PUBLIC_GRAPHQL_URL ?? 'http://localhost:4000/graphql',
    },
  },
  nitro: {
    preset: 'cloudflare_module',
  },
  vite: {
    optimizeDeps: {
      include: ['zod'],
    },
    plugins: voidModule?.voidPlugin ? [voidModule.voidPlugin()] : [],
  },
  typescript: {
    strict: true,
  },
})
