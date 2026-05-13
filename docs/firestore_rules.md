# Firestore Security Rules

Copy these rules into your Firebase Console > Firestore Database > Rules.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function: authenticated user
    function isAuthenticated() {
      return request.auth != null;
    }

    // Helper function: user owns document
    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    // User profile (read/write only by owner)
    match /users/{userId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }

    // User cycles (local-first sync)
    match /user_cycles/{userId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }

    // User daily logs (local-first sync)
    match /user_daily_logs/{userId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }

    // Partner links (owner can create; partner can update when accepting)
    match /partner_links/{linkId} {
      allow create: if isAuthenticated() && request.auth.uid == resource.data.ownerUid;
      allow read: if isAuthenticated() && (request.auth.uid == resource.data.ownerUid || request.auth.uid == resource.data.partnerUid);
      allow update: if isAuthenticated() && (request.auth.uid == resource.data.ownerUid || request.auth.uid == resource.data.partnerUid);
      allow delete: if isAuthenticated() && request.auth.uid == resource.data.ownerUid;
    }

    // Shared cycle data (owner writes; partner reads)
    match /shared_cycle_data/{ownerId} {
      allow read: if isAuthenticated() && (request.auth.uid == ownerId || request.auth.uid == resource.data.partnerUid);
      allow write: if isAuthenticated() && request.auth.uid == ownerId;
    }
  }
}
```

## Notes

- **Local-first design**: The app stores all data on-device via `SharedPreferences` / `AppDatabase`. Firestore is used only for optional backup and partner sharing.
- **Data minimization**: Only cycle summaries and explicitly shared fields are stored in Firestore. Detailed daily logs remain local unless the user chooses to sync.
- **Deletion**: When a user deletes their account, the app cleans up Firestore documents for that `uid` via batch delete.
