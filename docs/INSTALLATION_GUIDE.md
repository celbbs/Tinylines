# TinyLines — Installation Guide

**Team:** Celia Babbs, Kuenaokeao Borling, Charles Loughin, Arianna Joffrion  
**Course:** CS463-400 | Oregon State University | Spring 2026

---

## Overview

TinyLines is a Flutter-based mobile journaling app backed by Firebase. This guide covers how to set up the development environment, run the app, and build a distributable APK for Android.

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | ≥ 3.9.2 | Includes Dart SDK |
| Android Studio or VS Code | Latest | With Flutter/Dart extensions |
| Git | Any recent | For cloning the repo |
| Android SDK | API 21+ | Bundled with Android Studio |
| Java JDK | 17+ | Required by Android build tools |

> **iOS builds** additionally require a Mac with Xcode 15+ and an Apple Developer account for device deployment.

---

## Step 1 — Clone the Repository

```bash
git clone https://github.com/celbbs/Tinylines.git
cd Tinylines
```

Or extract the submitted `.zip` file and navigate into the project folder.

---

## Step 2 — Install Dependencies

```bash
flutter pub get
```

This downloads all packages listed in `pubspec.yaml` (Firebase, Provider, table_calendar, etc.).

---

## Step 3 — Firebase Configuration

The Firebase project (`tinylines-863ea`) is already configured in the codebase. The required config files are included:

| Platform | File | Location |
|----------|------|----------|
| Android | `google-services.json` | `android/app/` |
| iOS | `GoogleService-Info.plist` | `ios/Runner/` |
| Web/Other | `lib/firebase_options.dart` | Dart-generated, already present |

No additional Firebase setup is required for running the existing project — the backend is live and connected.

---

## Step 4 — Verify the Flutter Environment

```bash
flutter doctor
```

Resolve any issues flagged by `flutter doctor` before proceeding (typically: Android licenses, SDK path, or connected device).

---

## Step 5 — Run the App

### Option A: Android Emulator (Recommended)

1. Open Android Studio → **Device Manager** → create an emulator (Pixel 6, API 33+ recommended)
2. Start the emulator
3. In the project directory:

```bash
flutter run
```

Flutter will detect the running emulator and deploy the app automatically.

Alternatively, if you don't have Android Studio setup, you can use the CLI to launch emulators packaged with flutter by following these steps:

From the project root:
```bash
# See available emulators
flutter emulators

# Launch one
flutter emulators --launch <emulator_id>

# Confirm Flutter sees it
flutter devices

# Run the app
flutter run
```

Example:
```bash
$ flutter emulators
1 available emulator:

Id                  • Name                • Manufacturer • Platform

Medium_Phone_API_36 • Medium Phone API 36 • Generic      • android

To run an emulator, run 'flutter emulators --launch <emulator id>'.
To create a new emulator, run 'flutter emulators --create [--name xyz]'.

You can find more information on managing emulators at the links below:
  https://developer.android.com/studio/run/managing-avds
  https://developer.android.com/studio/command-line/avdmanager
```

### Option B: Physical Android Device

1. Enable **Developer Options** and **USB Debugging** on the device
2. Connect via USB
3. Run:

```bash
flutter run
```

### Option C: Run on iOS (Mac Only)

```bash
flutter run -d ios
```

> Requires Xcode, a signing certificate, and a provisioning profile. For evaluators without a Mac, use the Android APK (see below).

---

## Step 6 — Create an Account

When you first launch the app, you'll be asked to create an account. Any throwaway name and email will be sufficient, you will not be asked to confirm the email address.

1. Tap **Sign Up**
2. Enter your name, an email address, and a password (minimum 8 characters)
3. Tap **Create Account**

No pre-seeded test credentials are needed.

---

Now that you have an account and you're signed in, try creating some journal entries, modifying your user settings, etc.!

## Running the Tests

```bash
flutter test
```

To run a specific test file:

```bash
flutter test test/models/journal_entry_test.dart
flutter test test/providers/journal_provider_test.dart
flutter test test/services/storage_service_test.dart
```

---

## Project Structure (Key Directories)

```
Tinylines/
├── lib/                  # All Dart source code
│   ├── models/           # Data models
│   ├── providers/        # State management
│   ├── screens/          # UI screens
│   ├── services/         # Firebase + local storage
│   └── utils/            # Theme and utilities
├── test/                 # Unit, widget, and integration tests
├── android/              # Android native project files
├── ios/                  # iOS native project files
├── assets/               # Tutorial images
└── docs/                 # This documentation
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `flutter doctor` shows missing Android licenses | Run `flutter doctor --android-licenses` and accept all |
| Build fails with Gradle errors | Ensure JDK 17+ is installed and `JAVA_HOME` is set |
| Firebase Auth errors on first run | Check internet connectivity; Firebase requires a live connection for auth |
| `google-services.json not found` | Confirm the file exists at `android/app/google-services.json` |
| App crashes on launch | Ensure an emulator or device with API 21+ is being used |
