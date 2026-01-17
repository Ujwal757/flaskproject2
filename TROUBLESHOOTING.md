# Troubleshooting Registration Errors

## Common Registration Errors & Solutions

### 1. "An error occurred during registration"
This is a generic error. Check the console/debug output for the actual error message.

**Common causes:**
- Firebase not properly initialized
- Network connectivity issues
- Database permissions not set correctly

**Solution:**
- Check your console/debug output for the actual error
- Verify Firebase is properly configured (see `FIREBASE_SETUP.md`)
- Check your internet connection

### 2. "Email/Password authentication is not enabled"
**Solution:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Authentication** → **Sign-in method**
4. Click on **Email/Password**
5. Enable it and click **Save**

### 3. "Failed to create user profile"
This means authentication succeeded but database write failed.

**Possible causes:**
- Realtime Database security rules blocking writes
- Database not created
- Network issue during database write

**Solution:**
1. **Check Realtime Database exists:**
   - Go to Firebase Console → **Realtime Database**
   - Click **Create Database** if it doesn't exist

2. **Check Security Rules:**
   - Go to Firebase Console → **Realtime Database** → **Rules**
   - Use these rules:
   ```json
   {
     "rules": {
       "users": {
         "$userId": {
           ".read": "auth != null",
           ".write": "$userId === auth.uid || !data.exists()"
         }
       }
     }
   }
   ```

3. **Check Network:**
   - Ensure you have internet connection
   - Try again after a few seconds

### 4. "Network error" or "Network request failed"
**Solution:**
- Check your internet connection
- Try again after a few moments
- Check if Firebase services are accessible

### 5. "An account already exists for that email"
**Solution:**
- Use a different email address
- Or try logging in instead of registering

### 6. "The password provided is too weak"
**Solution:**
- Use a password with at least 6 characters
- Include numbers and special characters for stronger passwords

## Debugging Steps

1. **Check Console Output:**
   - Look for error messages in your IDE's debug console
   - The app now prints detailed error information

2. **Verify Firebase Setup:**
   - Ensure `firebase_options.dart` exists
   - Check `google-services.json` is in `android/app/`
   - Verify Firebase services are enabled

3. **Test Firebase Connection:**
   - Try logging in with an existing account
   - Check Firebase Console for any error logs

4. **Check Database Rules:**
   - Go to Firebase Console → Realtime Database → Rules
   - Ensure authenticated users can write to `/users/{userId}`

## Still Having Issues?

1. **Check the exact error message** in the console/debug output
2. **Share the error message** for more specific help
3. **Verify all Firebase services are enabled:**
   - Authentication (Email/Password)
   - Realtime Database
   - Storage

## Quick Checklist

- [ ] Firebase project created
- [ ] `firebase_options.dart` file exists
- [ ] `google-services.json` in `android/app/`
- [ ] Email/Password authentication enabled
- [ ] Realtime Database created
- [ ] Database security rules configured
- [ ] Internet connection active
- [ ] App has proper permissions

