# Fixed Realtime Database Rules (No Firebase Auth)

Since we're using Realtime Database authentication (not Firebase Auth), use these rules:

## Rules for Development

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

## Why This Works

- **`.read: "true"`** - Allows reading user data (needed for login)
- **`.write: "true"`** - Allows writing user data (needed for registration)
- **`.indexOn: ["email"]`** - Creates index for email queries

## Important Notes

⚠️ **These rules allow public read/write access.** This is fine for development, but for production you should:

1. Implement your own authentication checks in the app code
2. Add validation to prevent unauthorized access
3. Consider adding API keys or other security measures

## How to Apply

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Realtime Database** → **Rules** tab
4. Paste the rules above
5. Click **Publish**
6. Wait a few seconds for rules to propagate

## Alternative: More Restrictive Rules (If Needed)

If you want slightly more security while still allowing registration:

```json
{
  "rules": {
    "users": {
      ".indexOn": ["email"],
      "$userId": {
        ".read": "true",
        ".write": "!data.exists() || newData.child('id').val() === $userId"
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

This allows:
- Reading any user
- Creating new users (`!data.exists()`)
- Updating only if the user ID matches

Try the first set of rules first - they should work immediately!

