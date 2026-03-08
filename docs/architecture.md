# System Architecture

## Context
Shared Cab Platform enables route-sharing rides by matching passengers with overlapping paths and tracking driver movement in realtime.

## Core Components
- `apps/web`: user/admin interface (landing, auth, rides, dashboard map)
- `apps/api`: domain modules (`auth`, `users`, `rides`, `matching`, `routing`)
- `packages/shared`: common TS contracts and geo utilities
- Supabase: Auth + PostgreSQL/PostGIS + Realtime events
- OSRM: road-snapped route and polyline output

## Request Flow
1. User authenticates with Supabase Auth.
2. Frontend calls NestJS API using JWT bearer token.
3. API validates JWT with Supabase, executes SQL against PostGIS tables.
4. Ride creation invokes OSRM, stores polyline, and emits realtime update.
5. Matching queries compare route overlap using PostGIS intersection.
6. Dashboard subscribes to driver location changes via Supabase Realtime.

## Reliability Measures
- Zod env validation at startup.
- DTO-level validation with class-validator.
- Uniform API envelope for predictable client handling.
- Explicit status transition guard in rides service.
- Spatial indexes on all geography columns.