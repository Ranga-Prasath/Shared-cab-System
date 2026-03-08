# AGENTS.md

## Project: Shared Cab Platform
A ride-sharing system for passengers traveling along the same highway route.

## Architecture
- Monorepo (Turborepo + pnpm)
- Frontend: Next.js 15 (App Router) in /apps/web
- Backend: NestJS in /apps/api
- Shared types/constants: /packages/shared
- DB: Supabase (PostgreSQL + PostGIS)
- Auth: Supabase Auth (JWT verified in NestJS guards)
- Realtime cab tracking: Supabase Realtime channels
- Route engine: OSRM API for road-snapped routes

## Conventions
- All coordinates use [longitude, latitude] order (GeoJSON standard)
- Route polylines are encoded in Google Polyline format
- All API endpoints are versioned: /api/v1/...
- DTOs use class-validator decorators in NestJS
- Environment variables validated with Zod at startup
- Distances in meters, durations in seconds
- All timestamps in UTC ISO 8601

## Commands
- `pnpm dev` — Start all apps in dev mode
- `pnpm build` — Build all apps
- `pnpm test` — Run all tests
- `pnpm lint` — Lint all packages

## Skills
### Available skills
- frontend-pro: Build, review, refactor, and style frontend user interfaces in React, Next.js, Vue, or plain web stacks; use for responsive layouts, CSS/Tailwind styling, accessibility remediation, and frontend performance tuning. Do not use for backend logic, database schema changes, infrastructure, or CI/CD tasks. (file: /skills/frontend-pro/SKILL.md)
