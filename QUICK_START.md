# Quick Start - Firebase Setup

## The Error You're Seeing

```
FirebaseOptions cannot be null when creating the default app.
```

This happens because Firebase needs configuration files to connect to your Firebase project.

## Quick Fix (3 Steps)

### Step 1: Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### Step 2: Configure Firebase

```bash
flutterfire configure
```

This will:
- Detect your Firebase projects
- Let you select which project to use
- Generate `lib/firebase_options.dart` automatically
- Configure Android and iOS

### Step 3: Update main.dart

After running `flutterfire configure`, uncomment these lines in `lib/main.dart`:

```dart
import 'firebase_options.dart';  // Uncomment this

// And change:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,  // Uncomment this
);
```

## Alternative: Manual Setup

If you prefer manual setup:

1. **Create Firebase Project**: Go to [Firebase Console](https://console.firebase.google.com/)
2. **Add Android App**: Download `google-services.json` → Place in `android/app/`
3. **Enable Services**: 
   - Authentication (Email/Password)
   - Realtime Database
   - Storage
4. **Update main.dart**: The current code should work once `google-services.json` is in place

## What Services Do You Need?

For RoadVision AI, you need:

✅ **Firebase Authentication** - For user login/registration  
✅ **Realtime Database** - For storing reports and user data  
✅ **Firebase Storage** - For storing images  

**You DON'T need Firestore** - we're using Realtime Database instead!

## After Setup

Run:
```bash
flutter pub get
flutter run
```

The error should be gone! 🎉

For detailed instructions, see `FIREBASE_SETUP.md`

