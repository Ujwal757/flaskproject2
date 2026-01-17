# RoadVision AI - Setup Guide

## Prerequisites

1. Flutter SDK installed (version 3.9.2 or higher)
2. Firebase project created
3. Google Gemini API key

## Setup Steps

### 1. Install Dependencies

Run the following command to install all required packages:

```bash
flutter pub get
```

### 2. Firebase Configuration

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add your Flutter app to the Firebase project
3. Download the configuration files:
   - **Android**: `google-services.json` → Place in `android/app/`
   - **iOS**: `GoogleService-Info.plist` → Place in `ios/Runner/`
4. Enable the following Firebase services:
   - Authentication (Email/Password)
   - Cloud Firestore
   - Cloud Storage

### 3. Environment Variables

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your Gemini API key:
   ```
   GEMINI_API_KEY=your_actual_api_key_here
   ```

   Get your API key from: [Google AI Studio](https://makersuite.google.com/app/apikey)

### 4. Firebase Security Rules

Set up Firestore security rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'authority' ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'worker');
    }
    
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

Set up Storage security rules:

```javascript
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

### 5. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── models/
│   ├── report.dart      # Report data model
│   └── user.dart        # User data model
├── services/
│   └── gemini_service.dart  # AI analysis service
├── screens/
│   ├── auth/            # Authentication screens
│   ├── citizen/         # Citizen role screens
│   ├── authority/       # Authority role screens
│   └── worker/          # Worker role screens
├── widgets/             # Reusable UI components
├── utils/               # Helper functions
└── main.dart            # App entry point
```

## Next Steps

1. Create authentication screens (Login, Register)
2. Implement FirestoreService for database operations
3. Implement AuthService for user authentication
4. Create role-based navigation
5. Build citizen upload flow
6. Build authority dashboard
7. Build worker task management

## Key Features Implemented

✅ Project structure setup
✅ Dependencies configured
✅ Report model with all required fields
✅ User model with role management
✅ GeminiService with AI validation and damage detection
✅ Firebase initialization in main.dart
✅ Provider setup for state management

## Notes

- The GeminiService uses `gemini-1.5-flash` model for faster responses
- All AI responses are parsed as JSON for structured data
- The service includes fallback logic for non-JSON responses
- Report statuses: pending → assigned → inProgress → completed

