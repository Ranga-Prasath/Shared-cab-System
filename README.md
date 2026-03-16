# Shared Cab System

Shared Cab System is a Flutter web application for a Design Thinking course demo. It models a student-focused ride-sharing flow: create a ride, find compatible co-riders, split fares, track the trip on a live map, and complete a safety-focused end-to-end journey.

The project is built as a working product demo, not just a slideware prototype. It includes real Flutter UI, Riverpod state management, GoRouter navigation, browser geolocation, Firebase integration where configured, deterministic ride matching, and browser-backed smoke tests.

## What The App Does

- Lets a rider sign up or log in.
- Lets a rider create a direct or shared ride.
- Finds co-riders using the current matching standard: at least 35% route overlap within a 15-minute departure window.
- Applies night-mode safety constraints, including PIN verification and same-gender filtering where enabled.
- Tracks an active trip on a map with route progress and safety entry points.
- Supports recurring ride schedules for repeat commutes.
- Persists ride and user data through Firebase when the project is configured for it.

## Current Product Scope

This repo is strongest as a polished academic demo and engineering prototype. It has been hardened significantly, but some flows are still explicitly demo-scoped rather than production-integrated.

What is real in the app today:
- Flutter web client
- Firebase Auth and Firestore integration paths
- Matching pipeline and ride-session lifecycle
- Browser geolocation support
- Emergency contact management in profile data
- Unit, widget, and Playwright smoke coverage

What is still demo behavior:
- The app does not automatically notify law enforcement.
- Safety UX may guide the rider into panic/SOS flows without dispatching real-world emergency services.
- Live tracking quality depends on browser geolocation permissions and device support.

## Tech Stack

- Flutter
- Dart
- Riverpod
- GoRouter
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- flutter_map with OpenStreetMap tiles
- Geolocator
- Playwright for browser smoke tests

## Project Structure

```text
lib/
  core/        routing, services, matching, trip/session utilities
  data/        mock and demo data
  features/    auth, ride, matching, trip, safety, home, profile UI
  models/      ride, trip, user, location, preference, session models
  providers/   Riverpod state and derived app state
  main.dart    application entry point

test/          Flutter unit and widget tests
tests/         Playwright end-to-end smoke tests
web/           Flutter web shell
```

## Requirements

Before you run the project, make sure you have:

- Flutter SDK installed and available on `PATH`
- A Chromium-based browser or Chrome for browser mode
- Firebase configured if you want live backend behavior instead of demo fallback behavior
- Node.js installed if you want to run the Playwright suite

## Run The App

From the repo root:

```powershell
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5180
```

Then open [http://127.0.0.1:5180](http://127.0.0.1:5180).

If you want Flutter to launch a browser directly:

```powershell
flutter run -d chrome
```

If port `5180` is already in use, change the port:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5181
```

## Test The App

Flutter tests:

```powershell
flutter test
flutter analyze
```

Playwright browser smoke tests:

```powershell
npm install
npm run test:e2e
```

## Matching Standard

The current project standard is:

- Minimum 35% route overlap
- Maximum 15-minute departure gap

That standard is intentional and should be treated as the current product rule unless the matching policy is changed again in both code and documentation.

## Key User Flows

### Shared ride flow

1. Sign in.
2. Create a ride.
3. Search for co-riders.
4. Send or receive a join request.
5. Accept the shared ride.
6. Start and track the trip.
7. Complete the trip and rate riders.

### Direct ride flow

1. Sign in.
2. Create a ride.
3. Skip matching and start directly.
4. Track pickup and ride progress.
5. Complete the trip.

### Safety flow

1. Enter night mode automatically or by override.
2. Use same-gender filtering where applicable.
3. Verify arrival with the ride PIN.
4. Use panic/SOS screens if a ride feels unsafe.

## Notes For Reviewers

- This is a coursework demo, but the repo has been refactored toward stronger runtime correctness.
- Matching and ride-session logic are centralized instead of being spread across widget code.
- The codebase includes tests for critical lifecycle, matching, and safety paths.
- Browser-based testing is available through Playwright in addition to Flutter tests.

## Common Commands

Run the web server:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5180
```

Run in Chrome:

```powershell
flutter run -d chrome
```

Run analysis:

```powershell
flutter analyze
```

Run Flutter tests:

```powershell
flutter test
```

Run browser smoke tests:

```powershell
npm run test:e2e
```

## Disclaimer

This repository should not be represented as a fully production-ready emergency mobility platform. It is a serious demo application with meaningful engineering work behind it, but some safety-adjacent flows remain product demonstrations rather than real emergency dispatch systems.
