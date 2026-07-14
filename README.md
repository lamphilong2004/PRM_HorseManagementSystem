# Horse Racing Tournament Management System - Mobile (Flutter)

## Run

```bash
flutter pub get
flutter run
```

## Backend API

The Flutter app calls the production backend directly:

`https://managerhourse-be.onrender.com`

API integration is implemented with Dio in `lib/core/api`, JWT access tokens are attached by an interceptor, and sessions are persisted with Flutter Secure Storage.

## Implemented screens (minimal)

- Auth: Login / Register (role-based dev login)
- Home: role-based navigation
- Common: Tournaments, Races
- Owner: Horses
- Jockey: Invites
- Spectator: Predictions, Place Prediction, Race Results, Leaderboard, Notifications
- Referee: Race Operations, Report (placeholder)
- Admin: User Management, Scheduling (placeholder)
