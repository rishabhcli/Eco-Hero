# Firebase Backend Configuration Checklist

## ⚠️ CRITICAL: Verify Firebase Console Settings

Your app is configured correctly, but Firebase services might not be enabled in the Firebase Console backend.

### 🔐 Step 1: Enable Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **eco-hero-c907f**
3. Navigate to **Build** → **Authentication**
4. Click **Get Started** (if not already enabled)
5. Go to **Sign-in method** tab
6. Enable **Email/Password**:
   - Click on "Email/Password"
   - Toggle "Enable" to ON
   - Click "Save"

### 📊 Step 2: Enable Firestore Database

1. In Firebase Console, go to **Build** → **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (for development)
   - Location: Select closest to your region (e.g., `us-central`)
   - Click "Enable"
4. Security rules (will be set automatically from firestore.rules):
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

### 🔍 Step 3: Verify Project Settings

1. Go to **Project settings** (gear icon)
2. Verify:
   - ✅ Project ID: `eco-hero-c907f`
   - ✅ Bundle ID: `com.rishabh.Eco-Hero`
3. Under **Your apps**, check that iOS app is registered:
   - App nickname: Eco Hero
   - Bundle ID: com.rishabh.Eco-Hero
   - GoogleService-Info.plist downloaded

### 📱 Step 4: Deploy Firestore Security Rules

From terminal in project directory:
```bash
cd "/Users/rishabhbansal/Documents/GitHub/Eco-Hero"
firebase deploy --only firestore:rules
```

### ✅ Verification Commands

After enabling services, verify with:
```bash
# Check Firebase project
firebase projects:list

# Check Firestore indexes
firebase firestore:indexes

# Test Firebase connection
./verify_firebase.sh
```

## 🐛 Common Issues

### Issue: "Default FirebaseApp instance must be configured"
**Status:** ✅ FIXED - AppDelegate now configures Firebase before app launch

### Issue: "User authentication failed"
**Cause:** Email/Password authentication not enabled in Firebase Console
**Fix:** Follow Step 1 above

### Issue: "Firestore permission denied"
**Cause:** Firestore database not created or wrong security rules
**Fix:** Follow Step 2 above

### Issue: App crashes on launch with SIGABRT
**Possible causes:**
1. ❌ Authentication not enabled → Enable in Console (Step 1)
2. ❌ Firestore not created → Create database (Step 2)
3. ✅ GoogleService-Info.plist missing → FIXED
4. ✅ Firebase not configured → FIXED

## 🎯 Next Steps

1. **Enable Authentication** in Firebase Console (CRITICAL)
2. **Create Firestore Database** in Firebase Console (CRITICAL)
3. Run the app again
4. If still crashing, check Xcode console for specific error message

## 📝 Get Detailed Error

If crash persists, get the full error:
1. In Xcode, go to **Product** → **Run**
2. When app crashes, check bottom **Console** panel
3. Look for error message starting with:
   - "*** Terminating app due to uncaught exception"
   - "libc++abi: terminating"
   - Or any message right before SIGABRT

Copy and share the full error message for further debugging.
