# 🚕 Shared Cab System
# to run build
C:\tools\flutter\bin\flutter.bat run -d web-server --web-hostname 127.0.0.1 --web-port 5173

> **Design Thinking & Innovation Course — Demo Project**
> Built as a functional prototype to demonstrate human-centered design principles for shared urban mobility.

[![Flutter](https://img.shields.io/badge/Flutter-3.11-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Academic-green)]()

---

## 📋 About

This is a **demo project** for my **Design Thinking & Innovation** course in college. It showcases a shared cab-booking system designed for students and daily commuters — emphasizing **safety**, **affordability**, and **real-time tracking**.

The app demonstrates how design thinking methodology (Empathize → Define → Ideate → Prototype → Test) can be applied to solve the real-world problem of expensive solo cab rides, especially during late-night commutes.

### 🎯 Problem Statement

> Solo cab rides are expensive for students. Existing ride-sharing platforms don't optimize for route overlap or provide adequate safety features for night-time travel.

### 💡 Solution

A shared cab platform that:
- **Matches riders** with 80%+ route overlap within a 15-minute departure window
- **Splits fares** automatically (up to 67% savings)
- **Activates night safety mode** (9 PM – 6 AM) with SOS, safe arrival PIN, and emergency contacts
- **Tracks trips live** on a map with route deviation alerts

---

## ✨ Features

### Core Features
| Feature | Description |
|---------|-------------|
| 🔐 **Phone + OTP Auth** | Simulated login with OTP verification |
| 🗺️ **Ride Creation** | Pick locations from Chennai landmarks, set departure time |
| 🤝 **Smart Matching** | 80/15 Rule — ≥80% route overlap, ≤15 min departure gap |
| 💰 **Fare Splitting** | Auto-calculated per-head fare with savings % |
| ⭐ **Rider Ratings** | Post-trip rating system for co-riders |

### Safety Features (Night Mode)
| Feature | Description |
|---------|-------------|
| 🌙 **Auto Night Mode** | Dark theme + enhanced safety from 9 PM – 6 AM |
| 🔑 **Safe Arrival PIN** | 4-digit verification at destination |
| 🆘 **Panic Mode** | SOS to emergency contacts + police (100/108/112) |
| 👤 **Same-Gender Matching** | Optional filter for night rides |
| 📞 **Emergency Contacts** | Add/manage trusted contacts |

### Advanced Features
| Feature | Description |
|---------|-------------|
| 🗺️ **Map-Centric Trip View** | Full-screen OpenStreetMap with route polyline, animated cab, PICKUP/DROP markers — inspired by Ola/Uber/Rapido |
| 📡 **Live GPS Tracking** | Real-time browser geolocation with trail, pulsing dot, re-center FAB |
| ⚠️ **Route Deviation Alert** | Auto-detects when cab goes off-route, one-tap emergency contact alert |
| 🔄 **Recurring Ride Scheduler** | Set daily commute once, auto-match every day (day picker, time selector, swap button) |

---

## 🏗️ Architecture

```
lib/
├── core/
│   ├── router/          # GoRouter navigation (named routes)
│   └── theme/           # AppColors, AppTheme (day + night)
├── data/
│   └── mock/            # Mock data — users, locations, matches, deviations
├── features/
│   ├── auth/            # Login + OTP screens
│   ├── home/            # Dashboard with quick actions
│   ├── matching/        # Match list with overlap %, fare, savings
│   ├── profile/         # User profile, settings, night mode toggle
│   ├── rating/          # Post-trip star rating
│   ├── ride/            # Create ride, recurring rides, create schedule
│   ├── safety/          # Panic, safe arrival PIN, emergency contacts
│   ├── shell/           # Bottom nav app shell
│   └── trip/            # Trip status (map view), live GPS tracking, trip complete
├── models/              # User, Trip, RideRequest, Match, Location, RouteDeviation, RecurringRide
├── providers/           # Riverpod state — auth, ride, trip, night mode, GPS, safety, deviation
└── main.dart            # App entry point
```

### State Management

**Riverpod** providers manage all app state:

| Provider | Purpose |
|----------|---------|
| `currentUserProvider` | Active user session |
| `currentRideRequestProvider` | In-progress ride request |
| `activeTripProvider` | Ongoing trip state + status |
| `effectiveNightModeProvider` | Auto/manual night mode |
| `routeDeviationProvider` | Active route deviation alert |
| `recurringRidesProvider` | Saved ride schedules |
| `gpsTrackingActiveProvider` | GPS tracking status |

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.11 (Web) |
| **Language** | Dart 3.11 |
| **State** | Riverpod |
| **Navigation** | GoRouter |
| **Maps** | flutter_map + OpenStreetMap (free, no API key) |
| **GPS** | Geolocator (browser geolocation API) |
| **Animations** | flutter_animate |
| **Fonts** | Google Fonts (Inter) |
| **IDs** | UUID v4 |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.11.0
- Chrome browser (for web demo)

### Run

```bash
# Clone the repo
git clone https://github.com/Ranga-Prasath-22/shared-cab-system.git
cd shared-cab-system

# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome
```

### Demo Flow

```
Login (any phone) → Enter OTP (any 4 digits) → Home
  → Create Ride → Select Pickup & Drop → Find Matches
    → Accept Match → Trip Status (Map View!)
      → Watch cab animate along route
      → See deviation alert at ~60%
      → Complete Trip → Rate Riders
  → My Schedules → Create recurring ride
  → Profile → Toggle night mode, manage contacts
```

---

## 📊 Design Thinking Process

| Phase | What We Did |
|-------|-------------|
| **Empathize** | Interviewed 20+ college students about cab-sharing pain points |
| **Define** | "Students need affordable, safe shared rides with route-compatible co-riders" |
| **Ideate** | Brainstormed 15+ features; prioritized by impact vs. feasibility |
| **Prototype** | Built this Flutter web app as a functional prototype |
| **Test** | Demonstrated with mock data; validated UI/UX with peers |

---

## 📦 Dependencies

```yaml
flutter_riverpod: ^2.6.1    # State management
go_router: ^14.8.1           # Declarative routing
google_fonts: ^6.2.1         # Typography (Inter)
uuid: ^4.5.1                 # Unique IDs
flutter_animate: ^4.5.2      # Micro-animations
geolocator: ^14.0.2          # Browser GPS
flutter_map: ^8.2.2          # OpenStreetMap renderer
latlong2: ^0.9.1             # Coordinate math
```

---

## ⚠️ Disclaimer

This is an **academic demo project** built for coursework evaluation. All data is **mock/simulated** — no real backend, payments, or ride matching exists. The GPS tracking uses browser geolocation with a fallback to mock Chennai coordinates for reliability on desktop Chrome.

---

## 👤 Author

**Ranga Prasath** — CS Student
- GitHub: [@Ranga-Prasath-22](https://github.com/Ranga-Prasath-22)

Built with ❤️ for Design Thinking & Innovation Course, 2026.
