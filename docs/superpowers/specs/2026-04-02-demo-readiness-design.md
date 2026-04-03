# Shared Cab Demo Readiness Design (Academic MVP)

**Date:** 2026-04-02  
**Scope:** Demo completion for professor evaluation  
**Priority Order:** Product completeness -> matching quality -> reliability  
**Target Platforms:** Web + Android  
**Timeline:** 2-3 weeks  

## 1. Objective

Make the current repo demo-ready as a complete product experience without rewriting core architecture.  
The app should feel end-to-end complete in live presentation for:

- Rider request/join flow clarity
- Trip lifecycle continuity across screens
- Matching order stability under live updates

## 2. Constraints and Non-Goals

### Constraints

- Preserve existing session engine and matching pipeline.
- Use only additive schema/interface changes.
- Avoid destructive migrations and major backend rewrites.
- Prefer minimal, high-leverage refactors over broad feature expansion.

### Non-Goals

- No full production emergency dispatch integration.
- No large admin platform build in this cycle.
- No deep cross-service architecture redesign.

## 3. Approaches Considered

1. **UX-first stabilization** (recommended)  
   Fix rider-visible flow gaps first, then harden matching stability, then selective completeness.

2. Matching-engine first  
   Improves ranking quickly but leaves visible flow gaps that still look prototype-like.

3. Feature-complete sweep first  
   Higher scope risk for 2-3 weeks; likely inconsistent finish quality.

**Chosen strategy:** `1 -> 2 -> 3` (phased execution).

## 4. Proposed Design

### Phase A: UX-First Stabilization (Primary)

#### A1. Unified request-flow state contract

Standardize UI-visible states for host/rider flow:

- `idle`
- `requesting`
- `awaiting_host`
- `accepted_waiting_more`
- `accepted_ready`
- `declined`
- `cancelled`
- `expired`

Each state must have:

- clear user copy
- one primary next action
- deterministic transition guard

#### A2. Trip lifecycle continuity

Normalize transitions for:

- create ride -> waiting/matching
- request accepted/declined/cancelled -> next screen
- matched -> trip status -> completion

Add recovery entrypoints for refresh/re-entry so users resume in-progress context instead of landing in dead states.

#### A3. Interaction and feedback polish

For critical rider flow screens, enforce complete handling:

- loading state
- empty state
- recoverable error state with retry
- successful state

Unify destructive action UX (`cancel request`, `leave ride`) with confirmation and outcome feedback.

### Phase B: Matching Stability Hardening (Secondary)

#### B1. Deterministic rank ordering

Introduce explicit stable tie-break chain in ranking output to prevent random reorder churn between refreshes.

#### B2. Anti-jitter update handling

Apply a small stabilization window/debounce for list updates to avoid visual thrash while keeping responsiveness.

#### B3. Stability verification

Add deterministic tests ensuring equal inputs produce equal ordering across refresh cycles and boundary thresholds.

### Phase C: Selective Completeness Sweep (Tertiary)

#### C1. Flow-level completeness pass

Patch remaining dead ends in rider journey with explicit escape actions (`go home`, `retry`, `resume`).

#### C2. Demo operation helpers

Add dev/demo-only reset + seeded scenarios for repeatable judging runs.

#### C3. Packaging/readiness pass

Finalize practical web + Android demo runbook with reproducible startup and verification steps.

## 5. Interface and Schema Additions (Additive Only)

### Request lifecycle metadata

Add optional fields where applicable:

- `requestStatusUpdatedAt`
- `requestExpiryAt`
- `requestClientReasonCode`
- `flowVersion`

Behavior:

- Missing fields fallback to current behavior.
- New writes include fields when relevant.

### Matching output metadata

Add optional ranking metadata:

- `stableRankKey`
- `sortEpoch`

Behavior:

- Existing score logic remains.
- Metadata supports stable ordering and explainability/debugging.

### Session continuity hooks

Add lightweight recovery hooks in session controller, such as:

- `resumeIfRecoverable()`
- `currentFlowCheckpoint`

Behavior:

- No new trip model.
- Only used for continuity when app re-enters active flow.

## 6. Data Flow (High Level)

1. Rider creates ride -> request queue/matching stream emits candidates.
2. Matching layer evaluates + stable-sorts candidates.
3. Rider/host request decisions update queue state + lifecycle metadata.
4. Session controller checkpoints lifecycle progress.
5. On refresh/re-entry, app resolves checkpoint and resumes appropriate screen.

## 7. Error Handling and Failure Modes

- Request conflict races (accept vs cancel) must return deterministic user-facing outcome.
- Expired requests show explicit state and retry path.
- Stream disruptions show recoverable error state and allow refresh/retry.
- Missing additive fields from older records must not break flow.

## 8. Test Plan

### Unit tests

- request flow transitions (`send/wait/accept/decline/cancel/expire`)
- lifecycle checkpoint recovery
- ranking determinism and tie-break stability

### Widget tests

- request/join state rendering and action affordances
- host/rider conflict messaging
- transition guards between lifecycle screens

### Integration-style tests

- create -> request -> accept/decline/cancel -> trip -> complete
- refresh/re-entry recovery in non-terminal states

### Demo smoke tests

- seeded deterministic run for web
- scripted rehearsal checklist for Android

## 9. Acceptance Criteria

- Rider request flow no longer feels prototype-like.
- Lifecycle transitions are consistent and recoverable.
- Match ordering remains stable under repeated refresh.
- Additive schema changes remain backward-compatible.
- Web + Android demo runbook is repeatable.
- Analyze/tests remain green at each phase gate.

## 10. Execution Order

1. Phase A: UX-first stabilization
2. Phase B: matching stability hardening
3. Phase C: selective completeness sweep

No implementation begins from this spec until review approval.
