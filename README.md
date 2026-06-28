# SubSavr — Shared Subscription Intelligence

> **"SubSavr is a shared subscription intelligence layer that tracks, splits, and optimizes recurring digital expenses across groups — something autopay systems were never designed to do."**

## Autopay vs SubSavr

| Autopay (Banks/UPI) | SubSavr |
|---------------------|---------|
| Auto-deducts on due date | **Discovers** what you subscribe to |
| Single-user mandate | **Multi-user** groups & splits |
| Silent debit | **Smart reminders** (who paid, who didn't) |
| No analytics | **Spending trends** & duplicate detection |
| No group concept | **Settlement graph** (who owes whom) |
| Execution layer | **Intelligence layer** (sits above autopay) |

## What SubSavr Does

1. **Subscription Discovery** — Central graph of all active subscriptions and monthly burn
2. **Shared Economy** — Splitwise for subscriptions (equal / % / custom splits)
3. **Intelligence Layer** — Duplicate OTT detection, family plan suggestions, savings tracking
4. **Smart Alerts** — "Rahul hasn't paid Spotify", "Netflix renews in 3 days — 2 pending"
5. **Settlement Engine** — Graph-based debt minimization (A→B→C becomes A→C)
6. **Financial Visibility** — Category breakdown, group liability, savings from splits

## Tech Stack
- **BLoC** (`flutter_bloc`) + Clean Architecture
- **Firebase** (Auth, Firestore, FCM, Analytics, Crashlytics, Cloud Functions)
- **Hive** (offline cache) + **SharedPreferences**
- **go_router** for navigation
- **get_it** for dependency injection

## Setup

### 1. Flutter

```bash
flutter pub get
```

### 2. Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable: Authentication (Phone, Google, Apple), Firestore, FCM, Analytics, Crashlytics, Functions
3. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
4. Configure: `flutterfire configure`
5. Add SHA-1/SHA-256 for Android Google Sign-In
6. Enable Sign in with Apple + Push Notifications on iOS

### 3. Deploy backend

```bash
cd functions && npm install && npm run build
firebase deploy --only firestore:rules,functions
```

### 4. Run

```bash
flutter run
```

## Project Structure

```
lib/
├── core/           # Theme, errors, utils, widgets, services
├── features/       # auth, dashboard, subscriptions, groups, settlements, wallet, analytics, notifications, profile
├── injection_container.dart
└── main.dart
```

## Features

- Phone OTP, Google, Apple authentication
- Subscription CRUD with provider icons and smart categorization
- Groups with invite codes and QR join
- Expense splitting (equal, percentage, custom)
- Graph-based debt settlement (Splitwise-style minimization)
- Shared group wallet
- Real-time Firestore streams
- Offline-first with Hive cache and pending write queue
- Push + in-app notifications
- Analytics charts (fl_chart)
- AI insights (local stub + Cloud Function Gemini proxy)
- Gamification badges
- SubSavr Plus premium UI
- Dark mode

## Tests

```bash
flutter test
flutter test integration_test/
```

## CI

GitHub Actions runs `flutter analyze`, `flutter test`, and builds APK + iOS on every PR.
