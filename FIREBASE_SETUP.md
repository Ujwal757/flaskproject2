# Firebase Setup Guide for RoadVision AI

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Enter project name: "RoadVision AI" (or your preferred name)
4. Follow the setup wizard (disable Google Analytics if you don't need it)

## Step 2: Add Your Flutter App

### For Android:

1. In Firebase Console, click the Android icon (or "Add app")
2. Enter package name: `com.example.roadvision` (check your `android/app/build.gradle.kts` for the actual package name)
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

### For iOS (if needed):

1. In Firebase Console, click the iOS icon
2. Enter bundle ID (check `ios/Runner/Info.plist`)
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`

## Step 3: Enable Firebase Services

In Firebase Console, enable these services:

### 1. Authentication
- Go to **Authentication** → **Sign-in method**
- Enable **Email/Password**

### 2. Realtime Database
- Go to **Realtime Database** → **Create Database**
- Choose location (closest to your users)
- Start in **Test Mode** (we'll add security rules later)

### 3. Storage (for images)
- Go to **Storage** → **Get Started**
- Start in **Test Mode** (we'll add security rules later)

## Step 4: Get Firebase Configuration

You need to add Firebase options to your Flutter app. You have two options:

### Option A: Use flutterfire_cli (Recommended)

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Run configuration:
   ```bash
   flutterfire configure
   ```

3. Select your platforms (Android, iOS, Web, etc.)

This will automatically create `lib/firebase_options.dart` with your Firebase configuration.

### Option B: Manual Configuration

If you prefer manual setup, you can create `lib/firebase_options.dart` manually with your Firebase config values from the Firebase Console.

## Step 5: Update main.dart

After running `flutterfire configure`, update `main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const RoadVisionApp());
}
```

## Step 6: Set Up Realtime Database Security Rules

In Firebase Console → **Realtime Database** → **Rules**, use:

```json
{
  "rules": {
    "reports": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$reportId": {
        ".validate": "newData.hasChildren(['id', 'imageUrl', 'location', 'status', 'severity', 'damageType', 'description', 'userId', 'timestamp'])"
      }
    },
    "users": {
      "$userId": {
        ".read": "auth != null",
        ".write": "$userId === auth.uid || (auth != null && root.child('users').child(auth.uid).child('role').val() === 'authority')"
      }
    }
  }
}
```

## Step 7: Set Up Storage Security Rules

In Firebase Console → **Storage** → **Rules**, use:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /reports/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Step 8: Install Dependencies

```bash
flutter pub get
```

## Step 9: Test Your Setup

Run your app:
```bash
flutter run
```

The app should now connect to Firebase without errors!

## Troubleshooting

### Error: "FirebaseOptions cannot be null"

This means Firebase isn't properly configured. Make sure:
1. You've run `flutterfire configure` OR manually created `firebase_options.dart`
2. `google-services.json` is in `android/app/`
3. You've updated `main.dart` to use `DefaultFirebaseOptions.currentPlatform`

### Error: "Permission denied"

Check your Realtime Database and Storage security rules in Firebase Console.

### Package name mismatch

Make sure the package name in `google-services.json` matches your app's package name in `android/app/build.gradle.kts`.

## What You Need

✅ Firebase project created
✅ `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
✅ `firebase_options.dart` file (from `flutterfire configure`)
✅ Authentication enabled (Email/Password)
✅ Realtime Database created
✅ Storage enabled
✅ Security rules configured

That's it! Your app should now work with Firebase Realtime Database.

