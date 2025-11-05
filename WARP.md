# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

Project overview

- This is a two-part app:
  - Flutter client in lib/ (Android, iOS, macOS targets present) that talks to a local API.
  - Node.js/Express + MongoDB backend in back/ with JWT auth and optional AI analytics via Google Generative AI.

Key development commands

- Backend (Node/Express):
  - Install deps: npm install
  - Run API (expects env vars below): node back/server.js
- Flutter app:
  - Install deps: flutter pub get
  - Run on a device/simulator: flutter run
  - Lint/analyze Dart: flutter analyze
  - Format Dart: dart format .
  - Test all (no tests yet by default): flutter test
  - Run a single test by file/name: flutter test test/path_to_test.dart --name "pattern"
- Build mobile binaries:
  - Android APK (release): flutter build apk --release
  - iOS (requires Xcode setup): flutter build ios --release

Environment

- Backend reads from back/.env (not committed here). Required keys inferred from code:
  - MONGO_URI: MongoDB connection string
  - JWT_SECRET: secret for signing JWTs
  - GOOGLE_API_KEY: required to enable /api/analytics (Google Generative AI)
  - PORT: optional (defaults to 5001)

Big-picture architecture

- Flutter client
  - Entry point lib/main.dart sets MaterialApp routes: /home, /login, /register, /profile, /analytics, /entry_form, /report.
  - Auth flow: register/login hit http://localhost:5001/api/register and /api/login. On success, a JWT is stored via flutter_secure_storage under keys jwt_token, user_name, user_email.
  - Screens make authorized calls with Authorization: Bearer <token>:
    - HomeScreen: GET /api/entries/today to render today’s medications plan.
    - EntryFormScreen: POST /api/entries to upsert a daily health record (medications, headacheLevel, tags, notes).
    - ProfileScreen: GET/PUT /api/profile to view/update medical card metadata.
    - AnalyticsScreen: GET /api/analytics to fetch AI-generated insights from server.
  - Hardcoded API base is http://localhost:5001 in multiple screens; if the port/host changes, update those occurrences.
  - Notes for local emulators:
    - Android emulator should use http://10.0.2.2:5001 instead of localhost.
    - iOS simulator can reach http://localhost:5001 directly; physical devices must target your machine’s LAN IP.
- Backend (Express/Mongoose)
  - Entry back/server.js wires middleware, connects to MongoDB, and mounts route modules:
    - POST /api/register: hashes password with bcrypt, stores user, returns 201.
    - POST /api/login: validates credentials, issues a JWT ({ user: { id } }, 30d expiry).
    - /api/entries (routes/entries.js):
      - POST /: Upsert today’s HealthEntry for the authenticated user.
      - GET /today: Return the day’s medications array for the authenticated user.
    - /api/profile (routes/profile.js):
      - GET /: Return name, email, and medicalCard (password omitted).
      - PUT /: Replace medicalCard with request body.
    - /api/analytics (routes/analytics.js):
      - GET /: If user has >= 3 entries, builds a JSON prompt and calls Google Generative AI (gemini-pro) with GOOGLE_API_KEY; returns model text as insights.
  - Auth middleware back/middleware/auth.js parses Authorization: Bearer <token>, verifies with JWT_SECRET, and sets req.user.
  - Data models in back/User/:
    - User.js: name, email (unique), password (hashed), registeredAt, and medicalCard object (typed as a generic object with default shape).
    - HealthEntry.js: per-user daily entry with entryDate, medications[{ name, taken }], headacheLevel (0..10), symptomTags, lifestyleTags, notes.

Operational notes

- Port coordination: Flutter screens assume the API is on :5001; keep PORT aligned or update the Dart URLs.
- AI analytics are optional: if GOOGLE_API_KEY is missing, /api/analytics will fail; other endpoints continue to work.
- Linting: Dart lints are configured via analysis_options.yaml (flutter_lints). No JS linter/test runner is configured for the backend.
