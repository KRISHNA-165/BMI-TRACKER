# BMI Tracker & User Management Application

A feature-rich Flutter application built for tracking body mass index (BMI) over time with multi-profile support, Firebase Authentication, Cloud Firestore real-time synchronization, offline caching, and interactive weight history charts.

---

## 🌟 Key Features

1. **Authentication & Persistence**
   - Email & Password Sign Up and Login with inline validation.
   - Google Sign-In (`google_sign_in` integration).
   - "Forgot Password?" email reset flow with toast/snackbar confirmation.
   - Privacy Policy agreement requirement.
   - Auth state persistence across app restarts via `FirebaseAuth.instance.authStateChanges()`.
   - Automatic detect & fallback to **Demo Mode** with a prominent visual indicator if running locally without active Firebase credentials.

2. **Body Metrics & Pure BMI Calculation**
   - Calculation formula: $\text{BMI} = \frac{\text{weight (kg)}}{\text{height (m)}^2}$
   - Pure business logic in `lib/utils/bmi_calculator.dart` completely decoupled from Flutter UI.
   - Lossless unit conversions ($\text{kg} \leftrightarrow \text{lbs}$ and $\text{cm} \leftrightarrow \text{ft-in}$).
   - Date of Birth (DOB) date picker with exact age calculation and 1–120 years past date validation.
   - Color-coded badges & categories:
     - **Underweight**: $< 18.5$ (Cyan)
     - **Normal weight**: $18.5 – 24.9$ (Green)
     - **Overweight**: $25.0 – 29.9$ (Orange)
     - **Obese**: $\ge 30.0$ (Red)

3. **Multi-User Profile Management**
   - Single authenticated account holding multiple Profiles (e.g. "Self", "Spouse", "Child").
   - Profile Switcher UI dropdown at the top of the Home Dashboard.
   - Independent weight history and body metrics per profile.

4. **Weight History Line Chart (`fl_chart`)**
   - Interactive line graph showing chronological weight entries over time.
   - Touch tooltips displaying exact weight value and date.
   - Curved lines, gradient fill, and friendly empty state UI (< 2 data points).

---

## 🏗 Data Model (Cloud Firestore)

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

---

## 🛠 Tech Stack & Dependencies

- **Framework**: Flutter 3.41+ (Dart 3.11+)
- **State Management**: `flutter_riverpod`
- **Backend / Database**: `firebase_core`, `firebase_auth`, `google_sign_in`, `cloud_firestore`
- **Offline Cache**: `hive`, `shared_preferences`
- **Charting**: `fl_chart`
- **Typography & Formatting**: `google_fonts`, `intl`

---

## 🚀 Setup & Run Instructions

### Prerequisites
- Flutter SDK installed (`flutter --version`)
- macOS, Web browser, or Android/iOS Emulator

### Running Locally
```bash
# 1. Clone or navigate to project directory
cd /Users/balakrishnagunda/Desktop/APPDEV

# 2. Get dependencies
flutter pub get

# 3. Run unit tests
flutter test

# 4. Run application
flutter run -d macos    # For macOS Desktop
flutter run -d chrome   # For Web
```

---

## 🧪 Testing

Run the automated test suite covering pure BMI calculations, unit conversion functions, edge value categories ($18.5$, $25.0$, $29.9$, $30.0$), and form validation rules:

```bash
flutter test
```
