# NexQ — Authentication setup

Project: **nexq-fcebc**

## Firebase Console

1. [Authentication → Sign-in method](https://console.firebase.google.com/project/nexq-fcebc/authentication/providers)
   - Enable **Email/Password**
   - Enable **Google**

2. [Authorized domains](https://console.firebase.google.com/project/nexq-fcebc/authentication/settings) (for web)
   - `localhost`
   - Your production domain when deployed

## Web Client ID (configured in code)

`250135126119-5jhrlv1li4qmnothuuts9mjulhhel293.apps.googleusercontent.com`

Set in:
- `lib/core/firebase/firebase_auth_config.dart`
- `web/index.html` (`google-signin-client_id` meta tag)

## Android Google Sign-In

SHA-1 is registered; `google-services.json` includes OAuth clients.

Regenerate options after Firebase changes:

```powershell
cd mobile
flutterfire configure --project=nexq-fcebc
```

## Run

```powershell
cd mobile
flutter pub get
flutter run -d chrome    # web
flutter run              # Android
```

## Profile document (`users/{uid}`)

On sign-in or sign-up the app calls `UserRepository.ensureUserProfile()` which writes:

- `uid`, `id`, `email`, `displayName`, `role`, `createdAt`, `updatedAt`

Routing waits for this via `authSessionProvider` — you should **not** be sent back to `/login` while the profile is loading.

Deploy Firestore rules after changes:

```powershell
cd firebase
firebase deploy --only firestore:rules
```

## Debug logs

In debug builds, filter console for `[NexQ Auth]` to trace auth state, Firestore writes, and router redirects.

## Test checklist

- [ ] Email sign up → customer `/customer` or owner `/owner`
- [ ] Email login
- [ ] Google login (Chrome + Android)
- [ ] Kill app → reopen → still signed in
- [ ] Sign out from profile
