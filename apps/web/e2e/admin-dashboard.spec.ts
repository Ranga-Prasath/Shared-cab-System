import { test, expect } from '@playwright/test';

test('admin dashboard shows seeded rides and route overlay', async ({ page }) => {
  await page.goto('/auth/login');
  await page.getByPlaceholder('Email').fill('seed.admin@sharedcab.demo');
  await page.getByPlaceholder('Password').fill('SeedUser@123');
  await page.getByRole('button', { name: 'Sign in' }).click();
  await expect(page.getByText('Login successful.')).toBeVisible();

  await page.goto('/dashboard');
  await expect(page.locator('.leaflet-container')).toBeVisible();

  const rideCards = page.locator('[data-testid^="ride-card-"]');
  await expect(rideCards.first()).toBeVisible();

  await rideCards.first().click();
  await expect(page).toHaveURL(/ride=/);
  await expect(page.locator('path.route-overlay-core').first()).toBeVisible();
});