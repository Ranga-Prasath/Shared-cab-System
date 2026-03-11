// -- Shared Cab System --

# Shared Cab Feature Spec Template

## 1. Feature Summary
- Feature name:
- Owner:
- Date:
- Related screens/routes:
- Related agents (Rider, Matching, Trip, Safety, Geolocation):

## 2. Problem Statement
- Current behavior:
- Expected behavior:
- Why this matters (demo/professor validation/user impact):

## 3. Scope
- In scope:
- Out of scope:
- Assumptions:

## 4. User Flows
1. Host creates ride.
2. Rider requests to join.
3. Host accepts and chooses:
   - Wait for another rider
   - Proceed ride
4. Joined rider waiting state and optional cancel.
5. Trip starts only after required pickups are planned.

## 5. State Contract (Firestore + Model)
- Required ride fields:
  - `status`: `pending | requested | matched | declined | active | completed | cancelled`
  - `coRiderIds: string[]`
  - `requester*` fields for join requests
  - `waitForAnotherRider: bool`
  - `readyToProceed: bool`
  - cab sync fields (`cabLat`, `cabLng`, `cabBearing`, `cabSegmentIndex`, `cabSegmentProgress`, `cabUpdatedAt`)
- Transition rules:
  - request -> `requested`
  - accept+wait -> `pending` + `waitForAnotherRider=true` + joined co-rider
  - accept+proceed -> `matched` + `readyToProceed=true`
  - cancel joined rider -> remove from `coRiderIds`; if empty reset waiting flags

## 6. UI Requirements
- Host side:
  - Accept dialog with two explicit choices.
  - Incoming request card clear actions.
- Rider side:
  - Waiting for approval dialog.
  - Waiting for another rider dialog.
  - Cancel ride action while waiting.
- Shared:
  - Real-time navigation to trip only when `readyToProceed && status == matched`.

## 7. Routing/Trip Rules
- Pickup ordering:
  - Host pickup -> joined rider pickup(s) -> destination.
- Polyline continuity:
  - Route line must terminate at destination marker.
- Cab sync:
  - All tabs must consume shared cab sync state, not local-only simulation state.

## 8. Acceptance Criteria
- Host can accept and choose wait/proceed.
- Rider sees waiting-for-another-rider when host chooses wait.
- Rider can cancel while waiting and is removed from ride.
- Trip starts only when host proceeds.
- Route visually connects pickups and destination.
- Cab marker position is consistent across tabs (within sync tick tolerance).

## 9. Tests
- Unit:
  - Status transition tests for `acceptRequest`.
  - Co-rider removal test for `cancelJoinedRide`.
- Widget/integration:
  - Host accept dialog options.
  - Rider waiting dialog and cancel.
  - Proceed transition to trip screen.
- Manual:
  - Two-tab host+rider scenario.
  - Three-rider wait scenario.

## 10. Rollout & Risks
- Risks:
  - Race conditions on same ride doc updates.
  - Stale request fields blocking new requests.
- Mitigations:
  - Server timestamps / transactional updates if needed.
  - Cleanup of requester fields on accept/decline/cancel.

## 11. Done Checklist
- [ ] `dart format .`
- [ ] `dart analyze` (no errors)
- [ ] No hardcoded security credentials
- [ ] No unused imports/vars
- [ ] Host/rider flow manually validated in 2 browser tabs
