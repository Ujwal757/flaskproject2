# Fix Permission Denied Error

## Step 1: Verify Database Mode

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **roadvision-8ae26**
3. Go to **Realtime Database**
4. Check the **Mode** at the top:
   - If it says **"Locked Mode"** → Click **"Enable"** or switch to **"Test Mode"**
   - If it says **"Test Mode"** → That's fine, proceed to Step 2

## Step 2: Verify Rules Are Correct

Go to **Realtime Database** → **Rules** tab and use EXACTLY this (copy-paste):

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

**Important:**
- Use quotes around `"true"` (not boolean `true`)
- Make sure there are no extra commas
- Click **Publish** after pasting

## Step 3: Wait for Rules to Propagate

After publishing rules:
- Wait **20-30 seconds** for Firebase to update
- Close and restart your Flutter app
- Try registering again

## Step 4: Verify Database URL

Your database URL should be:
```
https://roadvision-8ae26-default-rtdb.firebaseio.com
```

This is already set in your `firebase_options.dart`, so it should work.

## Step 5: Check Database Location

1. In Firebase Console → **Realtime Database**
2. Check the **Location** (e.g., `us-central1`, `europe-west1`)
3. Make sure the database exists and is accessible

## Step 6: Test Database Connection

Try this in Firebase Console:
1. Go to **Realtime Database** → **Data** tab
2. Try manually adding a test node:
   - Click the `+` button
   - Add path: `test`
   - Add value: `"hello"`
   - If this works, the database is accessible

## Common Issues

### Issue 1: Database in Locked Mode
**Solution:** Switch to Test Mode or use the rules above

### Issue 2: Rules Not Published
**Solution:** Make sure you clicked **Publish** after updating rules

### Issue 3: Wrong Database
**Solution:** Verify you're editing the correct database (check the URL)

### Issue 4: Rules Syntax Error
**Solution:** Use the exact JSON format above with quotes around `"true"`

## Still Not Working?

If you still get permission denied:

1. **Check the exact error path:**
   - The error will tell you which path is denied
   - Make sure that path is covered in your rules

2. **Try Test Mode Rules:**
   ```json
   {
     "rules": {
       ".read": true,
       ".write": true
     }
   }
   ```
   (This allows everything - use only for testing!)

3. **Check Firebase Console Logs:**
   - Go to Firebase Console → **Realtime Database** → **Usage** tab
   - Check for any error messages

4. **Verify App is Connected:**
   - Make sure your app is using the correct Firebase project
   - Check `firebase_options.dart` has the correct `projectId`

## Quick Test

After updating rules, try this in your app:
- Register with a new email
- Check Firebase Console → Realtime Database → Data tab
- You should see a new user under `/users/{userId}`

If the user appears in the database but you still get an error, the issue is with reading, not writing.

