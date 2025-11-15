# ✅ Quick Start Checklist - Firebase Setup

Follow these steps in order to get Eco Hero fully working with Firebase.

---

## Step 1: Add Firebase Packages (2 minutes)

**In Xcode:**

1. ✅ Click "**Eco Hero**" project (blue icon in left sidebar)
2. ✅ Select "**Eco Hero**" under **TARGETS** (not PROJECTS)
3. ✅ Click "**General**" tab
4. ✅ Scroll to "**Frameworks, Libraries, and Embedded Content**"
5. ✅ Click "**+**" button
6. ✅ Add "**FirebaseAuth**" (search and select)
7. ✅ Add "**FirebaseFirestore**" (search and select)
8. ✅ Build: Press **Cmd + B**

**Expected Result:** ✅ BUILD SUCCEEDED

---

## Step 2: Enable Authentication in Firebase Console (1 minute)

1. ✅ Open Firebase Console: https://console.firebase.google.com/
2. ✅ Select your "**Eco Hero**" project
3. ✅ Click "**Authentication**" in left sidebar
4. ✅ Click "**Get Started**" (if first time)
5. ✅ Click "**Sign-in method**" tab
6. ✅ Click "**Email/Password**"
7. ✅ Toggle **Enable**
8. ✅ Click "**Save**"

**Expected Result:** Email/Password shows "Enabled" status

---

## Step 3: Create Firestore Database (3 minutes)

1. ✅ In Firebase Console, click "**Firestore Database**"
2. ✅ Click "**Create database**"
3. ✅ Select "**Start in production mode**" (we'll add rules next)
4. ✅ Choose location: **us-central1** (or your preferred region)
5. ✅ Click "**Enable**"

**Wait for database to be created (~30 seconds)**

---

## Step 4: Add Security Rules (2 minutes)

1. ✅ In Firestore Database, click "**Rules**" tab
2. ✅ Replace the content with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /activities/{activityId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /challenges/{challengeId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /achievements/{achievementId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

3. ✅ Click "**Publish**"

**Expected Result:** Rules published successfully

---

## Step 5: Test the App (5 minutes)

### Build and Run

1. ✅ In Xcode: Press **Cmd + R**
2. ✅ Wait for app to launch in simulator

### Test Sign Up

1. ✅ Click "**Sign Up**"
2. ✅ Enter email: `test@example.com`
3. ✅ Enter password: `test123456` (min 6 characters)
4. ✅ Enter name: `Test User`
5. ✅ Click "**Sign Up**"

**Expected Result:** App shows main dashboard

### Verify in Firebase Console - Authentication

1. ✅ Go to Firebase Console → **Authentication** → **Users**
2. ✅ You should see `test@example.com` in the user list

**Expected Result:** ✅ User appears in Firebase Auth

### Test Activity Logging

1. ✅ In app, go to "**Log Activity**" tab
2. ✅ Category: **Meals**
3. ✅ Activity: **Vegetarian Meal**
4. ✅ Click "**Log Activity**"
5. ✅ You should see success message

### Verify in Firebase Console - Firestore

1. ✅ Go to Firebase Console → **Firestore Database** → **Data**
2. ✅ Navigate to: `users` → `{your-user-id}` → `activities`
3. ✅ You should see the logged activity document

**Check these fields exist:**
- ✅ category: "Meals"
- ✅ description: "Vegetarian Meal"
- ✅ carbonSavedKg: 2.5
- ✅ waterSavedLiters: 3000
- ✅ timestamp
- ✅ createdAt

### Verify Profile Sync

1. ✅ In Firestore, click on the user document: `users/{user-id}`
2. ✅ Verify fields:
   - ✅ email: "test@example.com"
   - ✅ displayName: "Test User"
   - ✅ totalCarbonSavedKg: 2.5
   - ✅ totalWaterSavedLiters: 3000
   - ✅ currentLevel: 1 or 2
   - ✅ experiencePoints: 25+

**Expected Result:** ✅ All data synced successfully

### Test Offline Mode (Optional)

1. ✅ In simulator: Settings → Airplane Mode → **ON**
2. ✅ In app: Log another activity
3. ✅ Success message should appear
4. ✅ Disable Airplane Mode
5. ✅ Wait 5 seconds
6. ✅ Check Firestore - new activity should appear

**Expected Result:** ✅ Offline sync works

---

## Troubleshooting

### Build fails with "Unable to find module"
- ❌ **Problem:** FirebaseAuth or FirebaseFirestore not added to target
- ✅ **Solution:** Repeat Step 1, ensure packages are added to TARGET not PROJECT

### Sign up fails
- ❌ **Problem:** Email/Password not enabled in Firebase Console
- ✅ **Solution:** Repeat Step 2

### Data doesn't appear in Firestore
- ❌ **Problem:** Database not created or security rules blocking writes
- ✅ **Solution:** Repeat Steps 3 and 4

### "Permission denied" error
- ❌ **Problem:** Security rules too restrictive or user not authenticated
- ✅ **Solution:** Ensure you're signed in, check rules match Step 4

---

## Success Criteria

You'll know everything is working when:

✅ App builds without errors
✅ You can sign up with email/password
✅ User appears in Firebase Authentication
✅ Activities appear in Firestore after logging
✅ Profile shows correct impact metrics
✅ Dashboard displays your data
✅ Offline mode works

---

## What You'll Have

After completing these steps:

🎉 **Full Firebase Authentication**
- Email/password sign in/up
- Session persistence
- Password reset emails

🎉 **Cloud Data Sync**
- Activities synced to Firestore
- Profiles synced to Firestore
- Real-time backup

🎉 **Offline Support**
- App works without internet
- Auto-sync when connection restored

🎉 **Secure Data**
- Users can only access their own data
- Firebase security rules enforced

🎉 **Scalable Infrastructure**
- Unlimited users
- Auto-scaling
- Firebase reliability

---

## Time Estimate

| Step | Time |
|------|------|
| Add packages | 2 min |
| Enable auth | 1 min |
| Create database | 3 min |
| Security rules | 2 min |
| Testing | 5 min |
| **Total** | **~13 minutes** |

---

## Next Steps After This Works

Once everything is working:

1. 📱 **Test on real device** (not just simulator)
2. 🎨 **Add app icon** (if not done)
3. 🧪 **Create more test accounts**
4. 📊 **Monitor Firebase usage** in console
5. 🚀 **Consider TestFlight beta**

---

## Support Resources

- 📖 Firebase Auth Docs: https://firebase.google.com/docs/auth
- 📖 Firestore Docs: https://firebase.google.com/docs/firestore
- 📖 Security Rules: https://firebase.google.com/docs/firestore/security/get-started
- 📖 iOS Setup: https://firebase.google.com/docs/ios/setup

---

**Ready? Start with Step 1!**

Each step builds on the previous one, so follow them in order.

Good luck! 🚀

---

*Created: November 15, 2025*
*For: Eco Hero iOS App*
