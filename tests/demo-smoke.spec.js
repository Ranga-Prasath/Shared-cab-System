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
  for (let attempt = 0; attempt < 40; attempt++) {
    const accessibleCount = await page.evaluate(
      () => document.querySelectorAll('flt-semantics, [aria-label], [role]').length,
    );
    if (accessibleCount > 4) {
      return;
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

async function tripScreenText(page) {
  return await page.evaluate(() => document.body.innerText);
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
    limit: 100,
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
    limit: 100,
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

test.describe('Shared Cab demo regressions', () => {
  test.beforeEach(async ({ page }) => {
    await mockExternalApis(page);
  });

  test('searching co-riders opens the matches screen', async ({ page }) => {
    await page.goto('/#/create-ride');
    await enableFlutterSemantics(page);

    await selectRoute(page, {
      pickup: 'Codex Test Origin',
      dropoff: 'Codex Test Terminal',
    });

    await page.getByRole('button', { name: 'Search Co-Riders' }).click();

    await expect(page).toHaveURL(/#\/matches\//);
    await expect(page.getByText('Co-Riders Found')).toBeVisible();
    await expect(page.locator('body')).toContainText('Waiting for co-riders...');
    await expect(page.locator('body')).toContainText(
      'Book Direct Ride Instead',
    );
  });

  test('matches page can continue into the direct ride trip screen', async ({
    page,
  }) => {
    await page.goto('/#/matches/test');
    await enableFlutterSemantics(page);
    await expect(page).toHaveURL(/#\/matches\//);

    await page
      .getByRole('button', { name: 'Book Direct Ride Instead' })
      .click();

    await expect(page).toHaveURL(/#\/trip\//);
    await expect(page.getByText('Waiting for Pickup')).toBeVisible();
    await expect(page.getByRole('button', { name: 'GPS' })).toBeVisible();
  });

  test('matches route renders without blanking on a fresh browser context', async ({
    page,
  }) => {
    await page.goto('/#/matches/test');
    await enableFlutterSemantics(page);

    await expect(page.locator('body')).toContainText('Co-Riders Found');
    await expect(page.locator('body')).toContainText(/Waiting for co-riders|Share Ride/);
  });

  test('qa trip route renders for 2 riders without crashing', async ({
    page,
  }) => {
    await page.goto('/?qaTrip=2');
    await enableFlutterSemantics(page);

    const text = await tripScreenText(page);
    expect(text).toContain('Waiting for Pickup');
    expect(text).toContain(
      'QA pickup order: Queens Land Bus Stop -> Porur Junction',
    );
    expect(text).toContain('Queens Land Bus Stop');
    expect(text).toContain('Porur Junction');
    expect(text).toContain('Phoenix Marketcity');
  });

  test('qa trip route renders for 3 riders without crashing', async ({
    page,
  }) => {
    await page.goto('/?qaTrip=3');
    await enableFlutterSemantics(page);

    const text = await tripScreenText(page);
    expect(text).toContain('Waiting for Pickup');
    expect(text).toContain(
      'QA pickup order: Rajalakshmi Engineering College -> Queens Land Bus Stop -> Porur Junction',
    );
    expect(text).toContain('Rajalakshmi Engineering College');
    expect(text).toContain('Queens Land Bus Stop');
    expect(text).toContain('Porur Junction');
    expect(text).toContain('Phoenix Marketcity');
  });

  test('qa trip map controls expand and recenter with visible feedback', async ({
    page,
  }) => {
    await page.goto('/?qaTrip=3');
    await enableFlutterSemantics(page);

    await page.getByRole('button', { name: 'Expand map' }).click();
    await expect(page.locator('body')).toContainText('Full map mode');
    await page.getByRole('button', { name: 'Center on live position' }).click();
    await expect(page.locator('body')).toContainText(
      /Centered on the live cab|Centered on your live location|Showing the full trip route/,
    );
    await page.getByRole('button', { name: 'Exit full screen map' }).click();
    await expect(page.locator('body')).not.toContainText('Full map mode');
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
      await expect
        .poll(
          async () =>
            await userAPage
              .getByRole('group', { name: new RegExp(userB.name) })
              .count(),
          { timeout: 20_000 },
        )
        .toBeGreaterThan(0);
      await expect(
        userAPage.getByRole('button', { name: 'Share Ride' }).first(),
      ).toBeVisible();

      await userBPage.bringToFront();
      await expect
        .poll(
          async () =>
            await userBPage
              .getByRole('group', { name: new RegExp(userA.name) })
              .count(),
          { timeout: 20_000 },
        )
        .toBeGreaterThan(0);
      await expect(
        userBPage.getByRole('button', { name: 'Share Ride' }).first(),
      ).toBeVisible();
    } finally {
      await userAContext.close();
      await userBContext.close();
      await cleanupPlaywrightDemoDocs();
    }
  });
});
