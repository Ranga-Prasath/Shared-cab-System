import { test, expect } from '@playwright/test';

const FIREBASE_WEB_API_KEY = 'AIzaSyDJE-IP3E3W0g0cAyeEeGaYPfXEegdHrP4';
const FIRESTORE_REST_BASE =
  'https://firestore.googleapis.com/v1/projects/shared-cab-2/databases/(default)/documents';

async function mockExternalApis(page) {
  await page.route('https://nominatim.openstreetmap.org/**', async (route) => {
    const url = new URL(route.request().url());

    if (url.pathname.includes('/search')) {
      const query = (url.searchParams.get('q') || '').toLowerCase();

      if (query.includes('rajalakshmi engineering college')) {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify([
            {
              lat: '13.0386',
              lon: '80.0766',
              display_name:
                'Rajalakshmi Engineering College, parkwiz slot, Mevalurkuppam, Chennai',
            },
          ]),
        });
        return;
      }

      if (query.includes('tambaram railway station')) {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify([
            {
              lat: '12.9249',
              lon: '80.1000',
              display_name:
                'Tambaram Railway Station, Grand Southern Trunk Road, East Tambaram, Chennai',
            },
          ]),
        });
        return;
      }

      if (query.includes('poonamallee')) {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify([
            {
              lat: '13.0480',
              lon: '80.1086',
              display_name:
                'Poonamallee Bus Stand, Poonamallee High Road, Poonamallee, Chennai',
            },
          ]),
        });
        return;
      }

      if (query.includes('codex test origin')) {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify([
            {
              lat: '11.0150',
              lon: '78.9550',
              display_name: 'Codex Test Origin, Demo Corridor',
            },
          ]),
        });
        return;
      }

      if (query.includes('codex test terminal')) {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify([
            {
              lat: '10.8450',
              lon: '79.2050',
              display_name: 'Codex Test Terminal, Demo Corridor',
            },
          ]),
        });
        return;
      }

      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: '[]',
      });
      return;
    }

    if (url.pathname.includes('/reverse')) {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          display_name: 'Mock Address, Chennai',
          address: {
            road: 'Mock Road',
            suburb: 'Mock Area',
            city: 'Chennai',
          },
        }),
      });
      return;
    }

    await route.fallback();
  });

  await page.route(
    'https://router.project-osrm.org/route/v1/driving/**',
    async (route) => {
      const url = route.request().url();
      const coordinateChunk = url.split('/driving/')[1]?.split('?')[0] || '';
      const [start, end] = coordinateChunk.split(';');
      const [startLon, startLat] = start.split(',').map(Number);
      const [endLon, endLat] = end.split(',').map(Number);
      const routeKey = `${start};${end}`;
      const cannedRoutes = {
        '80.0766,13.0386;80.1000,12.9249': [
          [80.0766, 13.0386],
          [80.0820, 13.0250],
          [80.0890, 12.9950],
          [80.0945, 12.9650],
          [80.0980, 12.9420],
          [80.1000, 12.9249],
        ],
        '80.1086,13.0480;80.1000,12.9249': [
          [80.1086, 13.0480],
          [80.1010, 13.0150],
          [80.0890, 12.9950],
          [80.0945, 12.9650],
          [80.0980, 12.9420],
          [80.1000, 12.9249],
        ],
        '78.955,11.015;79.205,10.845': [
          [78.9550, 11.0150],
          [79.0050, 10.9900],
          [79.0650, 10.9550],
          [79.1200, 10.9150],
          [79.1650, 10.8800],
          [79.2050, 10.8450],
        ],
      };
      const coordinates = cannedRoutes[routeKey] ?? [
        [startLon, startLat],
        [(startLon + endLon) / 2, (startLat + endLat) / 2],
        [endLon, endLat],
      ];

      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          routes: [
            {
              geometry: {
                coordinates,
              },
            },
          ],
        }),
      });
    },
  );
}

async function enableFlutterSemantics(page) {
  await page.waitForLoadState('domcontentloaded');
  const enableAccessibilityButton = page.getByRole('button', {
    name: /Enable accessibility/i,
  });
  for (let attempt = 0; attempt < 60; attempt++) {
    if (await enableAccessibilityButton.count()) {
      await page.evaluate(() => {
        const placeholder =
          document.querySelector('flt-semantics-placeholder') ??
          document.querySelector('[aria-label="Enable accessibility"]');
        if (!placeholder) return;
        placeholder.dispatchEvent(
          new MouseEvent('click', {
            bubbles: true,
            cancelable: true,
            view: window,
          }),
        );
      });
    }

    await page.evaluate(() => {
      const toggle = document.querySelector('flt-semantics-placeholder');
      if (!toggle) return;
      toggle.dispatchEvent(
        new MouseEvent('click', {
          bubbles: true,
          cancelable: true,
          view: window,
        }),
      );
    });

    const [buttonCount, textboxCount, progressCount] = await Promise.all([
      page.getByRole('button').count(),
      page.getByRole('textbox').count(),
      page.getByRole('progressbar').count(),
    ]);
    const onlyEnableAccessibility =
      buttonCount === 1 &&
      textboxCount === 0 &&
      progressCount === 0 &&
      (await enableAccessibilityButton.count()) === 1;
    if (buttonCount + textboxCount + progressCount > 0 && !onlyEnableAccessibility) {
      return;
    }

    await page.keyboard.press('Tab').catch(() => {});
    await page.waitForTimeout(500);
  }

  throw new Error('Flutter semantics did not become interactive in time.');
}

async function enterSearchText(locator, value) {
  await locator.click();
  await locator.fill('');
  await locator.pressSequentially(value, { delay: 25 });
  await expect(locator).toHaveValue(value);
}

async function bringToFrontAndEnable(page) {
  await page.bringToFront();
  await enableFlutterSemantics(page);
}

async function signUpDemoUser(page, { name, email }) {
  await page.goto('/#/signup');
  await bringToFrontAndEnable(page);
  const textboxes = page.getByRole('textbox');
  await enterSearchText(textboxes.nth(0), name);
  await enterSearchText(textboxes.nth(1), email);
  await enterSearchText(textboxes.nth(2), '123456');
  await page.getByRole('button', { name: 'Male', exact: true }).click();
  await page.getByRole('button', { name: /Create Account/i }).click();
  await expect(page).toHaveURL(/#\/home/, { timeout: 25_000 });
}

async function selectRoute(page, { pickup, dropoff }) {
  const pickupSearch = page.getByRole('textbox', {
    name: /Search pickup place/i,
  });
  const dropoffSearch = page.getByRole('textbox', {
    name: /Search for a place/i,
  });

  await enterSearchText(pickupSearch, pickup);
  await expect(
    page.getByRole('button', {
      name: new RegExp(pickup, 'i'),
    }),
  ).toBeVisible();
  await page
    .getByRole('button', {
      name: new RegExp(pickup, 'i'),
    })
    .click();

  await enterSearchText(dropoffSearch, dropoff);
  await expect(
    page.getByRole('button', {
      name: new RegExp(dropoff, 'i'),
    }).first(),
  ).toBeVisible();
  await page
    .getByRole('button', {
      name: new RegExp(dropoff, 'i'),
    })
    .first()
    .click();
}

async function openCreateRideAndSearch(page, route) {
  await page.goto('/#/create-ride');
  await bringToFrontAndEnable(page);
  await selectRoute(page, route);
  await page.getByRole('button', { name: 'Search Co-Riders' }).click();
  await expect(page).toHaveURL(/#\/matches\//, { timeout: 25_000 });
}

async function openCreateRideAndStartNow(page, route) {
  await page.goto('/#/create-ride');
  await bringToFrontAndEnable(page);
  await selectRoute(page, route);
  await page.getByRole('button', { name: 'Start Ride Now' }).click();
  await expect(page).toHaveURL(/#\/trip\//, { timeout: 25_000 });
}

async function enableNightModeOverride(page) {
  await page.goto('/#/profile');
  await bringToFrontAndEnable(page);
  const switches = page.getByRole('switch');
  const nightModeSwitch = switches.first();
  const box = await nightModeSwitch.boundingBox();
  if (box) {
    await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  } else {
    await nightModeSwitch.click({ force: true });
  }
  await page.waitForTimeout(300);
}

function rideCardForUser(page, userName) {
  return page.getByRole('group', { name: new RegExp(`\\b${escapeRegExp(userName)}\\b`, 'i') });
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function clickFlutterLabel(page, label) {
  await page.evaluate((targetLabel) => {
    const candidates = Array.from(
      document.querySelectorAll('[aria-label], button, flt-semantics'),
    );
    const target = candidates.find((element) => {
      const aria = element.getAttribute('aria-label')?.trim();
      const text = element.textContent?.trim();
      return aria === targetLabel || text === targetLabel;
    });
    if (!target) {
      throw new Error(`Could not find "${targetLabel}" in Flutter semantics.`);
    }
    target.dispatchEvent(
      new MouseEvent('click', {
        bubbles: true,
        cancelable: true,
        view: window,
      }),
    );
  }, label);
}

async function clickLocatorCenter(page, locator) {
  const box = await locator.boundingBox();
  if (!box) {
    throw new Error('Could not resolve a clickable bounding box.');
  }
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
}

async function maybeConfirmJoinRequest(page) {
  const sendRequestButton = page.getByRole('button', { name: 'Send Request' });
  const isVisible = await sendRequestButton
    .first()
    .isVisible({ timeout: 2_000 })
    .catch(() => false);
  if (isVisible) {
    await clickFlutterLabel(page, 'Send Request');
  }
}

function getStringField(fields, fieldName) {
  return fields?.[fieldName]?.stringValue ?? '';
}

function getDocumentFieldMap(row) {
  return row?.document?.fields ?? {};
}

async function firestoreRunQuery(structuredQuery) {
  const response = await fetch(
    `${FIRESTORE_REST_BASE}:runQuery?key=${FIREBASE_WEB_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ structuredQuery }),
    },
  );
  if (!response.ok) {
    throw new Error(`runQuery failed: ${response.status}`);
  }
  return await response.json();
}

async function deleteFirestoreDocument(documentName) {
  const response = await fetch(
    `${FIRESTORE_REST_BASE}/${documentName.split('/documents/')[1]}?key=${FIREBASE_WEB_API_KEY}`,
    { method: 'DELETE' },
  );
  if (!response.ok && response.status !== 404) {
    throw new Error(`delete failed: ${response.status} ${documentName}`);
  }
}

async function cleanupPlaywrightDemoDocs() {
  const userRows = await firestoreRunQuery({
    from: [{ collectionId: 'users' }],
    limit: 500,
  });
  const testUsers = userRows
    .filter((row) => row.document)
    .filter((row) => {
      const fields = getDocumentFieldMap(row);
      const email = getStringField(fields, 'email');
      return (
        email.startsWith('sharedcab.alpha.') ||
        email.startsWith('sharedcab.bravo.')
      );
    });

  const userIds = new Set(
    testUsers.map((row) => getStringField(getDocumentFieldMap(row), 'id')),
  );

  const rideRows = await firestoreRunQuery({
    from: [{ collectionId: 'rides' }],
    orderBy: [{ field: { fieldPath: 'createdAt' }, direction: 'DESCENDING' }],
    limit: 500,
  });
  const testRides = rideRows
    .filter((row) => row.document)
    .filter((row) =>
      userIds.has(getStringField(getDocumentFieldMap(row), 'userId')),
    );

  await Promise.all(
    [...testRides, ...testUsers].map((row) =>
      deleteFirestoreDocument(row.document.name),
    ),
  );
}

async function withTimeout(promise, ms) {
  let timer;
  try {
    return await Promise.race([
      promise,
      new Promise((_, reject) => {
        timer = setTimeout(() => {
          reject(new Error(`Timed out after ${ms}ms`));
        }, ms);
      }),
    ]);
  } finally {
    clearTimeout(timer);
  }
}

async function safeCloseContext(context) {
  if (!context) return;
  await withTimeout(context.close().catch(() => {}), 5_000).catch(() => {});
}

async function safeCleanupPlaywrightDemoDocs() {
  await withTimeout(cleanupPlaywrightDemoDocs(), 20_000).catch(() => {});
}

test.describe('Shared Cab demo regressions', () => {
  test.beforeEach(async ({ page }) => {
    await mockExternalApis(page);
  });

  test.afterEach(async () => {
    await safeCleanupPlaywrightDemoDocs();
  });

  test('searching co-riders opens the matches screen', async ({ page }) => {
    const stamp = Date.now();
    await cleanupPlaywrightDemoDocs();
    try {
      await signUpDemoUser(page, {
        name: `Smoke ${stamp}`,
        email: `sharedcab.alpha.${stamp}@example.com`,
      });
      await openCreateRideAndSearch(page, {
        pickup: 'Codex Test Origin',
        dropoff: 'Codex Test Terminal',
      });
      await expect(page.getByText('Co-Riders Found')).toBeVisible();
      await expect(page.locator('body')).toContainText('Waiting for co-riders...');
      await expect(page.locator('body')).toContainText(
        'Book Direct Ride Instead',
      );
    } finally {
      await safeCleanupPlaywrightDemoDocs();
    }
  });

  test('protected routes redirect unauthenticated browsers to login', async ({
    page,
  }) => {
    await page.goto('/#/matches/some-ride-id');
    await enableFlutterSemantics(page);

    await expect(page).toHaveURL(/#\/login/);
    await expect(page.locator('body')).toContainText('Sign in to your account');
  });

  test('shared ride search can fall back into a direct trip screen', async ({
    page,
  }) => {
    const stamp = Date.now();
    await cleanupPlaywrightDemoDocs();
    try {
      await signUpDemoUser(page, {
        name: `Direct ${stamp}`,
        email: `sharedcab.alpha.${stamp}@example.com`,
      });

      await openCreateRideAndSearch(page, {
        pickup: 'Codex Test Origin',
        dropoff: 'Codex Test Terminal',
      });

      await page
        .getByRole('button', { name: 'Book Direct Ride Instead' })
        .click();

      await expect(page).toHaveURL(/#\/trip\//, { timeout: 25_000 });
      await expect(page.locator('body')).toContainText('Waiting for Pickup');
      await expect(page.getByRole('button', { name: 'GPS' })).toBeVisible();
    } finally {
      await safeCleanupPlaywrightDemoDocs();
    }
  });

  test('requester can cancel a pending join request before the host acts', async ({
    browser,
  }) => {
    test.slow();
    await cleanupPlaywrightDemoDocs();

    const hostContext = await browser.newContext({ serviceWorkers: 'block' });
    const requesterContext = await browser.newContext({
      serviceWorkers: 'block',
    });
    const hostPage = await hostContext.newPage();
    const requesterPage = await requesterContext.newPage();
    await mockExternalApis(hostPage);
    await mockExternalApis(requesterPage);

    const stamp = Date.now();
    try {
      await signUpDemoUser(hostPage, {
        name: `Host ${stamp}`,
        email: `sharedcab.alpha.${stamp}@example.com`,
      });
      await signUpDemoUser(requesterPage, {
        name: `Requester ${stamp}`,
        email: `sharedcab.bravo.${stamp}@example.com`,
      });

      await openCreateRideAndSearch(hostPage, {
        pickup: 'Rajalakshmi Engineering College',
        dropoff: 'Tambaram Railway Station',
      });
      await openCreateRideAndSearch(requesterPage, {
        pickup: 'Poonamallee',
        dropoff: 'Tambaram Railway Station',
      });

      await clickLocatorCenter(
        requesterPage,
        rideCardForUser(requesterPage, `Host ${stamp}`).getByRole('button', {
          name: 'Share Ride',
        }),
      );
      await maybeConfirmJoinRequest(requesterPage);
      await expect(requesterPage.locator('body')).toContainText(
        `Host ${stamp} is reviewing your request.`,
      );
      await expect(requesterPage.locator('body')).toContainText(
        'Cancel Request',
      );

      await expect(hostPage.locator('body')).toContainText('Ride Request', {
        timeout: 20_000,
      });

      await clickFlutterLabel(requesterPage, 'Cancel Request');

      await expect(requesterPage.locator('body')).not.toContainText(
        'Waiting for approval',
        {
          timeout: 20_000,
        },
      );
      await expect(
        rideCardForUser(requesterPage, `Host ${stamp}`).getByRole('button', {
          name: 'Share Ride',
        }),
      ).toBeVisible();
      await expect(hostPage.locator('body')).not.toContainText('Ride Request', {
        timeout: 20_000,
      });
    } finally {
      await safeCloseContext(hostContext);
      await safeCloseContext(requesterContext);
      await safeCleanupPlaywrightDemoDocs();
    }
  });

  test('host accepting a shared-ride request moves both riders into the trip', async ({
    browser,
  }) => {
    test.slow();
    await cleanupPlaywrightDemoDocs();

    const hostContext = await browser.newContext({ serviceWorkers: 'block' });
    const requesterContext = await browser.newContext({
      serviceWorkers: 'block',
    });
    const hostPage = await hostContext.newPage();
    const requesterPage = await requesterContext.newPage();
    await mockExternalApis(hostPage);
    await mockExternalApis(requesterPage);

    const stamp = Date.now();
    try {
      await signUpDemoUser(hostPage, {
        name: `Host ${stamp}`,
        email: `sharedcab.alpha.${stamp}@example.com`,
      });
      await signUpDemoUser(requesterPage, {
        name: `Requester ${stamp}`,
        email: `sharedcab.bravo.${stamp}@example.com`,
      });

      await openCreateRideAndSearch(hostPage, {
        pickup: 'Rajalakshmi Engineering College',
        dropoff: 'Tambaram Railway Station',
      });
      await openCreateRideAndSearch(requesterPage, {
        pickup: 'Poonamallee',
        dropoff: 'Tambaram Railway Station',
      });

      await clickLocatorCenter(
        requesterPage,
        rideCardForUser(requesterPage, `Host ${stamp}`).getByRole('button', {
          name: 'Share Ride',
        }),
      );
      await maybeConfirmJoinRequest(requesterPage);
      await expect(requesterPage.locator('body')).toContainText(
        `Host ${stamp} is reviewing your request.`,
      );
      await expect(requesterPage.locator('body')).toContainText(
        'Cancel Request',
      );

      await expect(hostPage.locator('body')).toContainText('Ride Request', {
        timeout: 20_000,
      });
      await bringToFrontAndEnable(hostPage);
      await clickFlutterLabel(hostPage, 'Accept Ride');
      await expect(hostPage.locator('body')).toContainText(
        'After accepting this rider',
      );
      await clickFlutterLabel(hostPage, 'Proceed Ride');

      await expect(hostPage).toHaveURL(/#\/trip\//, { timeout: 25_000 });
      await bringToFrontAndEnable(requesterPage);
      await expect(requesterPage).toHaveURL(/#\/trip\//, { timeout: 60_000 });
      await expect(hostPage.locator('body')).toContainText('Waiting for Pickup');
      await expect(requesterPage.locator('body')).toContainText(
        'Waiting for Pickup',
      );
      await expect(hostPage.getByRole('button', { name: 'GPS' })).toBeVisible();
      await expect(
        requesterPage.getByRole('button', { name: 'GPS' }),
      ).toBeVisible();
    } finally {
      await safeCloseContext(hostContext);
      await safeCloseContext(requesterContext);
      await safeCleanupPlaywrightDemoDocs();
    }
  });

  test('direct rides progress from pickup approach into in-progress state', async ({
    page,
  }) => {
    test.slow();
    test.setTimeout(160_000);
    const stamp = Date.now();
    await cleanupPlaywrightDemoDocs();
    try {
      await signUpDemoUser(page, {
        name: `Progress ${stamp}`,
        email: `sharedcab.alpha.${stamp}@example.com`,
      });

      await openCreateRideAndStartNow(page, {
        pickup: 'Codex Test Origin',
        dropoff: 'Codex Test Terminal',
      });

      await expect(page.locator('body')).toContainText('Waiting for Pickup');
      await expect(page.locator('body')).toContainText('Driver is on the way to pickup');
      await expect(page.locator('body')).toContainText('Ride in Progress', {
        timeout: 95_000,
      });
    } finally {
      await safeCleanupPlaywrightDemoDocs();
    }
  });

  test('night-mode trips can open the SOS safety screen from trip status', async ({
    page,
  }) => {
    test.slow();
    const stamp = Date.now();
    await cleanupPlaywrightDemoDocs();
    try {
      await signUpDemoUser(page, {
        name: `Safety ${stamp}`,
        email: `sharedcab.alpha.${stamp}@example.com`,
      });
      await enableNightModeOverride(page);

      await openCreateRideAndStartNow(page, {
        pickup: 'Codex Test Origin',
        dropoff: 'Codex Test Terminal',
      });

      await expect(page.getByRole('button', { name: 'SOS' })).toBeVisible();
      await clickFlutterLabel(page, 'SOS');
      await expect(page.locator('body')).toContainText('EMERGENCY');
      await expect(page.locator('body')).toContainText(
        'Tap the button below to enable emergency mode',
      );
      await clickFlutterLabel(page, 'SOS');
      await expect(page.locator('body')).toContainText('EMERGENCY MODE ON');
      await expect(page.locator('body')).toContainText(
        'This demo does not auto-message contacts',
      );
    } finally {
      await safeCleanupPlaywrightDemoDocs();
    }
  });

  test('two users searching co-riders see each other on overlapping routes', async ({
    browser,
  }) => {
    test.slow();
    await cleanupPlaywrightDemoDocs();

    const userAContext = await browser.newContext({
      serviceWorkers: 'block',
    });
    const userBContext = await browser.newContext({
      serviceWorkers: 'block',
    });

    const userAPage = await userAContext.newPage();
    const userBPage = await userBContext.newPage();
    await mockExternalApis(userAPage);
    await mockExternalApis(userBPage);

    const stamp = Date.now();
    const userA = {
      name: `Alpha ${stamp}`,
      email: `sharedcab.alpha.${stamp}@example.com`,
    };
    const userB = {
      name: `Bravo ${stamp}`,
      email: `sharedcab.bravo.${stamp}@example.com`,
    };

    try {
      await signUpDemoUser(userAPage, userA);
      await signUpDemoUser(userBPage, userB);

      await userAPage.goto('/#/create-ride');
      await bringToFrontAndEnable(userAPage);
      await selectRoute(userAPage, {
        pickup: 'Rajalakshmi Engineering College',
        dropoff: 'Tambaram Railway Station',
      });
      await userAPage.getByRole('button', { name: 'Search Co-Riders' }).click();
      await expect(userAPage).toHaveURL(/#\/matches\//, { timeout: 25_000 });

      await userBPage.goto('/#/create-ride');
      await bringToFrontAndEnable(userBPage);
      await selectRoute(userBPage, {
        pickup: 'Poonamallee',
        dropoff: 'Tambaram Railway Station',
      });
      await userBPage.getByRole('button', { name: 'Search Co-Riders' }).click();
      await expect(userBPage).toHaveURL(/#\/matches\//, { timeout: 25_000 });

      await userAPage.bringToFront();
      await expect(userAPage.locator('body')).toContainText('1 co-rider found!', {
        timeout: 20_000,
      });
      await expect(
        userAPage.getByRole('button', { name: 'Share Ride' }).first(),
      ).toBeVisible();

      await userBPage.bringToFront();
      await expect(userBPage.locator('body')).toContainText('1 co-rider found!', {
        timeout: 20_000,
      });
      await expect(
        userBPage.getByRole('button', { name: 'Share Ride' }).first(),
      ).toBeVisible();
    } finally {
      await safeCloseContext(userAContext);
      await safeCloseContext(userBContext);
      await safeCleanupPlaywrightDemoDocs();
    }
  });

  test('mobile-sized browsers still show co-rider cards for both riders', async ({
    browser,
  }) => {
    test.slow();
    await cleanupPlaywrightDemoDocs();

    const mobileContextOptions = {
      serviceWorkers: 'block',
      viewport: { width: 412, height: 915 },
      isMobile: true,
      hasTouch: true,
    };
    const userAContext = await browser.newContext(mobileContextOptions);
    const userBContext = await browser.newContext(mobileContextOptions);

    const userAPage = await userAContext.newPage();
    const userBPage = await userBContext.newPage();
    await mockExternalApis(userAPage);
    await mockExternalApis(userBPage);

    const stamp = Date.now();
    const userA = {
      name: `Alpha Mobile ${stamp}`,
      email: `sharedcab.alpha.${stamp}@example.com`,
    };
    const userB = {
      name: `Bravo Mobile ${stamp}`,
      email: `sharedcab.bravo.${stamp}@example.com`,
    };

    try {
      await signUpDemoUser(userAPage, userA);
      await signUpDemoUser(userBPage, userB);

      await userAPage.goto('/#/create-ride');
      await bringToFrontAndEnable(userAPage);
      await selectRoute(userAPage, {
        pickup: 'Rajalakshmi Engineering College',
        dropoff: 'Tambaram Railway Station',
      });
      await userAPage.getByRole('button', { name: 'Search Co-Riders' }).click();
      await expect(userAPage).toHaveURL(/#\/matches\//, { timeout: 25_000 });

      await userBPage.goto('/#/create-ride');
      await bringToFrontAndEnable(userBPage);
      await selectRoute(userBPage, {
        pickup: 'Poonamallee',
        dropoff: 'Tambaram Railway Station',
      });
      await userBPage.getByRole('button', { name: 'Search Co-Riders' }).click();
      await expect(userBPage).toHaveURL(/#\/matches\//, { timeout: 25_000 });

      await expect(userAPage.locator('body')).toContainText('1 co-rider found!', {
        timeout: 20_000,
      });
      await expect(
        userAPage.getByRole('button', { name: 'Share Ride' }).first(),
      ).toBeVisible();

      await expect(userBPage.locator('body')).toContainText('1 co-rider found!', {
        timeout: 20_000,
      });
      await expect(
        userBPage.getByRole('button', { name: 'Share Ride' }).first(),
      ).toBeVisible();
    } finally {
      await safeCloseContext(userAContext);
      await safeCloseContext(userBContext);
      await safeCleanupPlaywrightDemoDocs();
    }
  });
});
