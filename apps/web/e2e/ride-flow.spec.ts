import { test, expect } from '@playwright/test';

test('signup to ride request flow', async ({ page }) => {
  await page.goto('/auth/signup');
  await page.getByPlaceholder('Full name').fill('Demo User');
  await page.getByPlaceholder('Phone').fill('+919999999999');
  await page.getByPlaceholder('Email').fill('demo@example.com');
  await page.getByPlaceholder('Password').fill('Password123!');
  await page.getByRole('button', { name: 'Create account' }).click();

  await page.goto('/rides');
  await page.getByRole('button', { name: 'Request Ride' }).click();
  await expect(page.getByText('Ride requested successfully.')).toBeVisible();
});