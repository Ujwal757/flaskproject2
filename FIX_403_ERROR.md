# Fix 403 Permission Denied Error

The error occurs because FlutterFire CLI doesn't have permission to automatically download `google-services.json`. Here's how to fix it:

## Solution: Manually Add Android App and Download Config File

### Step 1: Add Android App Manually in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **NEW Firebase project** (the one you just created)
3. Click the **Android icon** (or click "Add app" and select Android)
4. Enter these details:
   - **Android package name:** `com.example.roadvision`
   - **App nickname (optional):** RoadVision Android
   - **Debug signing certificate SHA-1 (optional):** Leave empty for now
5. Click **"Register app"**

### Step 2: Download google-services.json

1. On the next screen, click **"Download google-services.json"**
2. Save the file to your computer (usually goes to Downloads folder)

### Step 3: Place google-services.json in Your Project

**Option A: Using File Explorer (Easiest)**

1. Copy the downloaded `google-services.json` file
2. Navigate to: `C:\Users\USER\Desktop\Flutter projects\roadvision\android\app\`
3. Paste/Replace the `google-services.json` file there

**Option B: Using PowerShell**

```powershell
# Replace <path-to-downloads> with your Downloads folder path
# Example: C:\Users\USER\Downloads\google-services.json

Copy-Item "C:\Users\USER\Downloads\google-services.json" -Destination "C:\Users\USER\Desktop\Flutter projects\roadvision\android\app\google-services.json" -Force
```

### Step 4: Continue with FlutterFire Configure

Now you can run `flutterfire configure` again, but **skip Android** since you've already added it manually:

```powershell
flutterfire configure
```

When prompted to select platforms:
- ✅ Press spacebar to **deselect Android** (since you added it manually)
- ✅ Keep **Web** selected (if using web)
- ✅ Keep **Windows** selected (if using Windows)
- ✅ Select other platforms as needed
- Press Enter to continue

This will update `firebase_options.dart` with your new project configuration while skipping the Android config (which you already added manually).

## Alternative: Skip Android Entirely (If Not Using Android)

If you're only testing on **Web** or **Windows**, you can skip Android configuration:

```powershell
flutterfire configure
```

When prompted:
- ❌ **Deselect Android** (press spacebar)
- ✅ Keep **Web** and **Windows** selected
- Press Enter

The app will work fine on Web/Windows without Android configuration.

## Verify Configuration

After completing the steps:

1. Check `lib/firebase_options.dart` - should have your new project ID
2. Check `android/app/google-services.json` - should have your new project info
3. Run `flutter clean && flutter pub get`
4. Test the app - registration should now work with the new Firebase project

## Summary

The key issue was that FlutterFire CLI needs explicit permissions to download service files. By manually:
1. Adding the Android app in Firebase Console
2. Downloading the `google-services.json` file
3. Placing it in the correct location

You bypass the permission issue and continue with the configuration process.
