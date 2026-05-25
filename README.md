# NexQ — Smart Realtime Queue Management

Monorepo for **NexQ** (QueueLess): customer mobile app, shop owner dashboard, admin web panel, and Firebase backend.

## Project Structure

```
nexq/
├── mobile/          # Flutter app (customers + shop owners)
├── admin/           # Next.js admin panel
├── firebase/        # Firestore rules, indexes, hosting config
└── README.md
```

## Tech Stack

| Layer | Stack |
|-------|--------|
| Mobile | Flutter, Riverpod, GoRouter, Material 3 |
| Backend | Firebase Auth, Firestore, FCM, Storage |
| Admin | Next.js, TypeScript, Tailwind, Recharts |

## Zero-Cost MVP

- No Google Maps / Places / Distance Matrix APIs
- City + area filters instead of paid geolocation
- External Google Maps app for navigation (`url_launcher`)
- Firestore reads/writes optimized with pagination and targeted listeners

---

## 1. Firebase Setup

```powershell
# Install CLI
npm install -g firebase-tools

# Login & create project at https://console.firebase.google.com
firebase login
firebase use --add YOUR_PROJECT_ID

# Enable: Authentication (Email + Google), Firestore, Storage, FCM, Hosting
```

Deploy rules and indexes:

```powershell
cd firebase
firebase deploy --only firestore:rules,firestore:indexes,storage
```

### Flutter Firebase config

```powershell
cd mobile
dart pub global activate flutterfire_cli
flutterfire configure
```

Replace placeholders in `mobile/lib/core/firebase/firebase_options.dart` if not auto-generated.

### Admin env

Copy `admin/.env.example` to `admin/.env.local` and fill Firebase web config values.

---

## 2. Mobile App

```powershell
cd mobile
flutter pub get
flutter run
```

### Features

- **Customer**: splash, onboarding, auth, home (categories, city/area filter, search), shop details, queue request, live tracking, notifications, profile
- **Owner**: shop registration, dashboard, queue management (approve/reject/delay/next/skip/pause)
- **Roles**: `customer`, `shop_owner`, `admin` (stored in Firestore `users` collection)

### Create admin user

After first signup, set role in Firestore:

```
users/{uid} → role: "admin"
```

---

## 3. Admin Panel

```powershell
cd admin
npm install
npm run dev
```

Open http://localhost:3000 — login with an admin account.

Pages: Dashboard, Shops (approve/ban), Queues, Users, Reports.

### Deploy to Vercel

```powershell
cd admin
vercel
```

Set environment variables in Vercel dashboard (same as `.env.local`).

### Deploy to Firebase Hosting

```powershell
cd admin
npm run build
# Configure next export or use Vercel; hosting public folder points to admin/out
```

---

## 4. Android Release Build

```powershell
cd mobile
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

Add `google-services.json` to `mobile/android/app/` after Firebase Android app registration.

---

## 5. Firestore Collections

| Collection | Purpose |
|------------|---------|
| `users` | Profiles, roles, FCM tokens, saved shops |
| `shops` | Shop data, queue state, approval status |
| `queue_requests` | Customer queue requests |
| `active_tokens` | Live queue tokens |
| `notifications` | In-app notifications |
| `reviews` | Shop reviews |
| `categories` | Service categories (auto-seeded) |

---

## 6. Security

- `firebase/firestore.rules` — role-based access
- `firebase/storage.rules` — owner-only shop uploads
- Customers read/write own data; owners manage own shops; admins full access

---

## 7. Queue Engine Rules

1. No duplicate active requests per customer per shop
2. Owner approval before token assignment
3. Atomic token increment via Firestore transactions
4. Pause freezes movement; cancel removes tokens
5. Completed tokens archived
6. FCM + local notifications for key events

---

## License

Proprietary — NexQ MVP
