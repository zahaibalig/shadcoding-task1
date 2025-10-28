import { fileURLToPath } from 'node:url'
import { mergeConfig, defineConfig, configDefaults } from 'vitest/config'
import viteConfig from './vite.config'

export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      environment: 'jsdom',
      exclude: [...configDefaults.exclude, 'e2e/**'],
      root: fileURLToPath(new URL('./', import.meta.url)),
      globals: true,
      // Set environment mode to 'test' to load .env.test file
      env: {
        // Vitest automatically loads .env.test when mode is 'test'
        // But we can also explicitly set env vars here if needed
      },
      coverage: {
        provider: 'v8',
        reporter: ['text', 'json', 'html'],
        exclude: [
          'node_modules/',
          'dist/',
          '**/*.config.*',
          '**/mockData.ts',
          '**/*.d.ts',
        ],
      },
    },
  })
)
