# Shared Cab Platform

Production-oriented shared cab system scaffold with Next.js 15 frontend and NestJS backend in a Turborepo monorepo.

## Architecture Overview
- Monorepo: Turborepo + pnpm
- Web app: `apps/web` (Next.js 15 App Router + Tailwind + Leaflet + Supabase Realtime)
- API: `apps/api` (NestJS + Supabase Auth verification + Postgres/PostGIS + OSRM integration)
- Shared package: `packages/shared` (types, statuses, geometry utilities)
- API spec source of truth: `docs/openapi.yaml`
- DB schema: `supabase/migrations/001_initial_schema.sql`

## Setup
1. Install dependencies:
```bash
pnpm install
```
2. Configure env:
```bash
cp .env.example .env
```
3. Run apps:
```bash
pnpm dev
```
4. Open:
- Web: `http://localhost:3000`
- API docs: `http://localhost:4000/api/docs`

## Commands
- `pnpm dev` - run web + api
- `pnpm build` - build all packages
- `pnpm test` - run unit tests + e2e test targets
- `pnpm lint` - run type/lint checks

## Professor Demo Script (2-user flow)
1. Open two browser sessions (User A and User B), both on `/dashboard`.
2. User A signs up, goes to `/rides`, creates a ride request.
3. User B sees ride list update on dashboard after API fetch and realtime updates from gateway/realtime channels.
4. In API (or admin flow), trigger `/api/v1/rides/:id/match` and update status `/api/v1/rides/:id/status`.
5. Both sessions observe updated status and route overlays.
6. In Supabase SQL editor, upsert rows into `driver_locations`; dashboard map markers animate live.

## Testing
- Backend unit tests:
```bash
pnpm --filter @shared-cab/api test
```
- Shared polyline tests:
```bash
pnpm --filter @shared-cab/shared test
```
- Web E2E:
```bash
pnpm --filter @shared-cab/web test:e2e
```

## Known Demo Limitations
- Matching SQL uses geometric overlap approximation with buffered line segments; tune thresholds for production.
- Dashboard currently uses open map tiles and demo marker rendering without clustering.
- E2E test assumes local auth/network availability and is not fully mocked.
- Full operational lifecycle (dispatch/driver app/payments) is intentionally out of scope.