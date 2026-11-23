# HealthBridge

**HealthBridge** is an offline-first Flutter app for Community Health Workers (CHWs) in Rwanda. CHWs record patient visits and danger signs on the phone; urgent cases are relayed to the health centre over the internet, or via encrypted SMS when there is no data connection. The project also includes a Next.js supervisor/admin dashboard and a Node.js/Express server.

---

## Repository layout

```
health_bridge/
├── lib/                  # Flutter app
│   ├── core/             # Auth, API client, theme, shared widgets
│   ├── data/             # Drift (SQLite/SQLCipher) repositories and providers
│   ├── domain/           # Entities, repository interfaces, use cases
│   ├── presentation/     # Screens and controllers (Riverpod)
│   ├── sync/             # Background Firestore sync engine
│   └── urgent/           # SMS alert dispatcher
├── server/               # Node.js / Express back-end
│   └── src/
│       ├── admin/        # Account & reset-request routes
│       ├── devices/      # Device registration
│       ├── sms/          # SMS webhook, codec, keystore
│       ├── supervisor/   # Supervisor routes
│       └── visits/       # Visit merge logic
├── dashboard/            # Next.js supervisor/admin web app
│   ├── app/              # Next.js App Router pages
│   ├── components/       # React components
│   └── lib/              # API helpers (admin.ts, history.ts)
├── docs/                 # ERD and other design documents
├── firestore.rules       # Firestore security rules
├── firestore.indexes.json
└── pubspec.yaml
```

---

## Prerequisites

| Tool | Minimum version | Notes |
|---|---|---|
| Flutter | 3.32+ (Dart SDK ^3.13.2) | `flutter --version` |
| Android Studio / Xcode | latest stable | for mobile targets |
| Node.js | 18 LTS | server & dashboard |
| npm | 9+ | comes with Node 18 |
| Firebase CLI | latest | `npm i -g firebase-tools` |
| A Firebase project | — | see Firebase setup below |

---

## 1. Clone the repository

```bash
git clone https://github.com/nshderrick056/HealthBridge.git
cd HealthBridge
```

---

## 2. Firebase setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Authentication** (Email/Password) and **Cloud Firestore** (location `africa-south1`).
3. Download the config files for each platform and place them:
   - **Android**: `android/app/google-services.json`
   - **iOS / macOS**: `ios/Runner/GoogleService-Info.plist` and `macos/Runner/GoogleService-Info.plist`
   - **Web (dashboard)**: add the Firebase config object to `dashboard/lib/firebase.ts` (create if absent).
4. Deploy Firestore rules and indexes:

```bash
firebase login
firebase use <your-project-id>
firebase deploy --only firestore
```

---

## 3. Flutter app

### Install dependencies

```bash
flutter pub get
```

### Generate Drift database code

The local database uses [Drift](https://drift.simonbinder.eu/) with SQLCipher for encryption at rest. Run the code generator once after a fresh clone or whenever you change a table schema:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run on a device or emulator

```bash
flutter run
```

Specify a target if you have multiple devices:

```bash
flutter run -d <device-id>   # flutter devices to list
```

### Run tests

```bash
flutter test
```

---

## 4. Server

The Express server handles account management, device registration, the SMS webhook, and alert state transitions. It uses the Firebase Admin SDK, so it bypasses Firestore security rules.

```bash
cd server
npm install
```

Create a `.env` file in `server/` with the following variables:

```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_SERVICE_ACCOUNT_KEY=path/to/serviceAccountKey.json  # or inline JSON
SMS_WEBHOOK_SECRET=your-sms-gateway-secret
PORT=3000
```

Download a service-account key from **Firebase console → Project settings → Service accounts → Generate new private key** and point `FIREBASE_SERVICE_ACCOUNT_KEY` at it. Never commit this file.

Start the server:

```bash
npm run dev      # development (ts-node / nodemon)
npm run build    # compile TypeScript
npm start        # production (compiled output)
```

Run server tests:

```bash
npm test
```

---

## 5. Dashboard (Next.js)

```bash
cd dashboard
npm install
```

Create a `.env.local` file in `dashboard/` with your Firebase web config:

```env
NEXT_PUBLIC_FIREBASE_API_KEY=...
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=...
NEXT_PUBLIC_FIREBASE_PROJECT_ID=...
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=...
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=...
NEXT_PUBLIC_FIREBASE_APP_ID=...
```

Start the development server:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

Build for production:

```bash
npm run build
npm start
```

---
 

---

## Architecture overview

- **Offline-first**: all patient and visit data is stored in a local SQLCipher database (Drift). Every write also adds an outbox row; the background sync engine (`lib/sync/`) uploads queued records to Firestore when connectivity returns.
- **Urgent alerts**: if a visit has danger signs, the urgent dispatcher (`lib/urgent/`) tries the internet channel first, then falls back to an AES-encrypted SMS.
- **Roles**: `chw`, `supervisor`, and `admin` are set as Firebase Auth custom claims by the server when an account is created. Firestore rules enforce them so no client can escalate its own access.
- **IDs on the phone**: patients and visits get UUID v4 IDs offline. A repeated upload is idempotent — it lands on the same Firestore document instead of creating a duplicate.

For the full data model see [docs/ERD.md](docs/ERD.md).

---
 