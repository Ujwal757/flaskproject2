# Guide: Switch to a New Firebase Project

## Step 1: Logout from Current Firebase Account

1. Open a web browser and go to [Firebase Console](https://console.firebase.google.com/)
2. Click on your profile icon (top right)
3. Click **"Sign out"** or switch accounts
4. Sign in with your **NEW email** (the one you want to use)

## Step 2: Create a New Firebase Project

1. In Firebase Console, click **"Add project"** (or "Create a project")
2. Enter a project name (e.g., "RoadVision" or "RoadVisionAI")
3. Click **"Continue"**
4. **Disable Google Analytics** (optional - click "Not now" or disable it)
5. Click **"Create project"**
6. Wait for the project to be created (takes 10-30 seconds)
7. Click **"Continue"** when ready

## Step 3: Enable Required Firebase Services

### 3.1 Enable Realtime Database

1. In the left sidebar, click **"Realtime Database"**
2. Click **"Create Database"**
3. Choose a location closest to your users (e.g., `us-central1`, `europe-west1`)
4. Choose **"Start in test mode"** (we'll add rules later)
5. Click **"Enable"**

### 3.2 Enable Storage (for images)

1. In the left sidebar, click **"Storage"**
2. Click **"Get started"**
3. Choose **"Start in test mode"**
4. Click **"Next"** → Select the same location as your database
5. Click **"Done"**

### 3.3 Set Database Rules

1. Go to **Realtime Database** → **Rules** tab
2. Copy and paste these rules:

```json
{
  "rules": {
    "users": {
      ".indexOn": ["email"],
      "$userId": {
        ".read": "true",
        ".write": "true"
      }
    },
    "reports": {
      ".read": "true",
      ".write": "true",
      "$reportId": {
        ".indexOn": ["severity", "status", "assignedWorkerId", "timestamp"]
      }
    }
  }
}
```

3. Click **"Publish"**

## Step 4: Add Flutter App to New Firebase Project

### 4.1 Add Android App Manually (IMPORTANT - Do this first!)

Due to permission issues with FlutterFire CLI, add Android app manually:

1. In Firebase Console, click the **Android icon** (or "Add app" → Android)
2. Enter package name: `com.example.roadvision`
3. Click **"Register app"**
4. Click **"Download google-services.json"**
5. **Copy** the downloaded file to: `android/app/google-services.json`
   - Full path: `C:\Users\USER\Desktop\Flutter projects\roadvision\android\app\google-services.json`
6. Replace the old file if it exists

### 4.2 Install FlutterFire CLI (if not installed)

Open terminal/command prompt and run:

```bash
dart pub global activate flutterfire_cli
```

### 4.3 Run FlutterFire Configure

Navigate to your project directory:

```bash
cd "C:\Users\USER\Desktop\Flutter projects\roadvision"
```

Then run:

```bash
flutterfire configure
```

### 4.4 Select Your Platforms

When prompted:
1. Select your platforms (press spacebar to select):
   - ✅ **Web** (required)
   - ❌ **Android** (DESELECT - you already added it manually)
   - ✅ **Windows** (if you have Windows app)
   - ✅ **iOS** (if you have iOS app - Mac only)
   - ✅ **macOS** (if you have macOS app - Mac only)

2. Select your **NEW Firebase project** from the list
3. Press **Enter** to continue

This will:
- Update `lib/firebase_options.dart` with new configuration
- Skip Android (since you added it manually in Step 4.1)
- Configure other platforms automatically

**Note:** If you get a 403 error for Android, you can safely ignore it if you've already manually added the Android app and placed `google-services.json` in the correct location.

## Step 5: Verify Configuration

After running `flutterfire configure`, check:

1. **`lib/firebase_options.dart`** - Should have new project ID and URLs
2. **`android/app/google-services.json`** - Should be updated (if Android is configured)

## Step 6: Clean and Rebuild Your App

Run these commands to clean and rebuild:

```bash
flutter clean
flutter pub get
flutter run
```

## Step 7: Test Registration

1. Run your app
2. Try registering a new citizen account
3. Check Firebase Console → Realtime Database → Data tab
4. You should see new user data appearing

## Troubleshooting

### Issue: "Firebase CLI not found"
**Solution:** Install Firebase CLI first:
```bash
npm install -g firebase-tools
```

### Issue: "No projects found"
**Solution:** 
- Make sure you're logged into Firebase Console with your NEW email
- Verify the project was created successfully
- Try refreshing: `flutterfire configure --refresh-token`

### Issue: Database not found
**Solution:**
- Make sure you created the Realtime Database in Step 3.1
- Verify the database URL in `firebase_options.dart` matches your Firebase Console

### Issue: Still connecting to old project
**Solution:**
1. Delete `firebase.json` if it exists (this stores project config)
2. Run `flutter clean`
3. Run `flutterfire configure` again
4. Make sure to select the NEW project

## Important Notes

⚠️ **Data Migration:** 
- Your old project data will **NOT** be automatically migrated
- You'll need to manually export/import data if you want to keep old users/reports
- Or start fresh with the new project (recommended for development)

✅ **After switching:**
- All new registrations will go to the new Firebase project
- Old project data remains untouched
- You can still access the old project with the old email if needed
