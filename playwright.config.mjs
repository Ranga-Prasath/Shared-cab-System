/**
 * SPEC: Playwright Demo Regression Tests
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * WHAT IT DOES:
 *   Runs stable browser regression checks against the built Flutter web app,
 *   including the create-ride to co-rider flow and the matches screen render.
 *
 * DATA OBJECTS:
 *   Demo route form — pickup query, drop-off query, co-rider search CTA
 *   Matches screen — route id, waiting state text, fallback actions
 *
 * OPERATIONS:
 *   serve build/web → local base URL
 *   open create ride → fill pickup/drop-off → open co-rider search
 *   open matches route directly → verify the page renders instead of blanking
 *
 * EDGE CASES HANDLED:
 *   • Flutter semantics are disabled by default, so tests enable them first
 *   • Flutter service workers are blocked to avoid stale cached JS between runs
 *   • Local server is reused when already running to keep the demo workflow fast
 *
 * ASSUMPTIONS MADE:
 *   • The app is verified from the compiled `build/web` output, not `flutter run`
 *   • Geocoding returns Rajalakshmi Engineering College and Tambaram Railway Station
 *   • Chromium is sufficient for the live demo regression pass
 *
 * DONE WHEN:
 *   `npm run test:e2e` starts the local server, opens the built app in Chromium,
 *   and passes both the create-ride co-rider flow and direct matches route render test.
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 */

import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 45_000,
  expect: {
    timeout: 10_000,
  },
  fullyParallel: false,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: 'http://127.0.0.1:4173',
    browserName: 'chromium',
    headless: true,
    serviceWorkers: 'block',
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
    video: 'retain-on-failure',
    viewport: { width: 1280, height: 720 },
  },
  webServer: {
    command: 'node scripts/serve_spa.mjs build/web 4173',
    port: 4173,
    reuseExistingServer: true,
    timeout: 120_000,
  },
});
