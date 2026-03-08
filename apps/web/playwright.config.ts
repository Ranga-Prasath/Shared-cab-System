import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  globalSetup: './e2e/global-setup.ts',
  use: {
    baseURL: 'http://localhost:3000',
    headless: true
  },
  webServer: [
    {
      command: 'corepack pnpm --filter @shared-cab/api dev',
      port: 4000,
      timeout: 120000,
      reuseExistingServer: !process.env.CI
    },
    {
      command: 'corepack pnpm --filter @shared-cab/web dev',
      port: 3000,
      timeout: 120000,
      reuseExistingServer: !process.env.CI
    }
  ]
});