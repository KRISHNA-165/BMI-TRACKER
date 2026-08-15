# BMI Tracker & Health Metrics Application - Technical Documentation

This document provides a comprehensive guide to the **BMI Tracker Application**, covering the application setup, key libraries and dependencies, special security/firebase configurations, and detailed instructions for building, running, and deploying the app.

---

## 📌 1. App Setup

### System Requirements
* **Flutter SDK**: `^3.11.1` or higher
* **Dart SDK**: `^3.11.1`
* **Firebase CLI**: Installed (`npm install -g firebase-tools`)
* **Android Studio / Android SDK**: Platform tools with `adb`

### Firebase Project Architecture
The application is configured with Firebase for user authentication and real-time database persistence.

* **Firebase Project ID**: `bmical-ac87d`
* **Android Configuration**: Integrated via `android/app/google-services.json`
* **iOS / macOS Configuration**: Integrated via `ios/Runner/GoogleService-Info.plist` and `macos/Runner/GoogleService-Info.plist`
* **Flutter Options**: Configured via `lib/firebase_options.dart`
* **Firebase CLI Mapping**: Configured in `firebase.json` for rules deployment

---

## 📦 2. Key Libraries & Dependencies

| Library | Version | Purpose |
| :--- | :--- | :--- |
| **`flutter_riverpod`** | `^2.6.1` | Reactive state management for Auth state, Profiles, Weight History, and UI themes |
| **`firebase_core`** | `^3.12.0` | Initializing Firebase app instance across platforms |
| **`firebase_auth`** | `^5.5.1` | Email/Password authentication, Password Reset, and Auth state streams |
| **`google_sign_in`** | `^6.2.2` | OAuth 2.0 integration for Google Sign-In |
| **`cloud_firestore`** | `^5.6.5` | NoSQL Cloud Database with offline persistence & real-time sync |
| **`fl_chart`** | `^0.70.2` | Interactive, customizable weight trend line graphs with tooltips |
| **`hive`** / **`hive_flutter`** | `^2.2.3` / `^1.1.0` | Fast key-value local offline cache storage |
| **`shared_preferences`** | `^2.5.2` | Simple key-value storage for local user preference caching |
| **`intl`** | `^0.20.2` | Date formatting, age calculations, and currency/metric formatting |
| **`google_fonts`** | `^6.2.1` | Typography styling (Inter font family) |

---

## ⚙️ 3. Special Configurations

### A. Cloud Firestore Security Rules
Security rules ensure users can only access their own user document, profiles, and weight history records.

Location: `firestore.rules`

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User root document and nested subcollections
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Profiles subcollection: users/{userId}/profiles/{profileId}
      match /profiles/{profileId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
        
        // Weight History subcollection: users/{userId}/profiles/{profileId}/weightHistory/{entryId}
        match /weightHistory/{entryId} {
          allow read, write: if request.auth != null && request.auth.uid == userId;
        }
      }
    }
  }
}
```

### B. Firestore Database Structure
```
users (collection)
└── {userId} (doc)
    ├── email: string
    ├── createdAt: timestamp
    └── profiles (subcollection)
        └── {profileId} (doc)
            ├── name: string
            ├── gender: string
            ├── dob: timestamp
            ├── heightCm: number
            ├── weightKg: number
            ├── unitPreference: { height: "cm"|"ft", weight: "kg"|"lbs" }
            ├── currentBmi: number
            ├── bmiCategory: string
            └── weightHistory (subcollection)
                └── {entryId} (doc)
                    ├── weightKg: number
                    └── loggedAt: timestamp
```

### C. Pure BMI Calculation Logic
The calculation and unit conversion engine is fully decoupled from the UI in `lib/utils/bmi_calculator.dart`:
* Formula: $\text{BMI} = \frac{\text{weight (kg)}}{\text{height (m)}^2}$
* Unit conversion utilities for $\text{kg} \leftrightarrow \text{lbs}$ and $\text{cm} \leftrightarrow \text{ft-in}$

---

## 🚀 4. Instructions to Build and Run

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Deploy Firestore Security Rules
Deploy security rules directly to the connected Firebase project (`bmical-ac87d`):
```bash
firebase deploy --only firestore:rules --project bmical-ac87d
```

### Step 3: Run in Debug Mode
Run on an attached Android device, iOS simulator, or desktop target:
```bash
# List available target devices
flutter devices

# Run on macOS Desktop
flutter run -d macos

# Run on Android Emulator / Connected Phone
flutter run -d android
```

### Step 4: Build Release APKs (Android)
Build optimized, architecture-split APKs:
```bash
flutter clean
flutter pub get
flutter build apk --release --split-per-abi
```

**Output Binaries**:
* `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (For modern 64-bit Android phones/emulators)
* `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (For older 32-bit ARM devices)
* `build/app/outputs/flutter-apk/app-x86_64-release.apk` (For 64-bit x86 emulators)

### Step 5: Install APK via ADB
```bash
# Launch Android Emulator (if not already running)
flutter emulators --launch Medium_Phone_API_36.1

# Install release APK onto emulator/device
~/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Step 6: Run Unit & Integration Tests
Run automated test suite covering pure BMI calculations, date picker validations, and category thresholds:
```bash
flutter test
```
