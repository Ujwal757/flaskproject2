# Realtime Database Security Rules

## Required Rules for RoadVision AI

Copy and paste these rules into your Firebase Console → Realtime Database → Rules:

```json
{
  "rules": {
    "users": {
      ".indexOn": ["email"],
      "$userId": {
        ".read": "true",
        ".write": "!data.exists() || $userId === auth.uid"
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

## Explanation

### Users Collection
- **`.indexOn: ["email"]`** - Required index for querying users by email (for login)
- **`.read: true`** - Allow reading user data (needed for login verification)
- **`.write: !data.exists() || $userId === auth.uid`** - Allow creating new users OR updating own profile

### Reports Collection
- **`.read: true`** - Allow reading reports
- **`.write: true`** - Allow writing reports
- **Indexes** - For efficient querying by severity, status, worker ID, and timestamp

## How to Apply

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Realtime Database** → **Rules** tab
4. Paste the rules above
5. Click **Publish**

## Important Notes

⚠️ **For Production**: These rules allow public read/write. For production, you should:
- Add authentication checks
- Restrict writes to authenticated users only
- Add role-based access control

Example production rules:
```json
{
  "rules": {
    "users": {
      ".indexOn": ["email"],
      "$userId": {
        ".read": "auth != null",
        ".write": "auth != null && (!data.exists() || $userId === auth.uid)"
      }
    },
    "reports": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

However, since we're not using Firebase Auth, the current rules work for development.

