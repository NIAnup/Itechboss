# VAULT — Secure Session & Encrypted Storage Demo

A production-grade Flutter application built for the **Secure Session & Encrypted Storage** assignment. Integrates with the public DummyJSON Auth API and demonstrates hardened local cryptography, single-flight token interceptor management, PBKDF2 PIN app lock, root/jailbreak detection, and anti-screenshot privacy protection.

---

## 1. Prerequisites & Environment Setup

### Required Toolchain Versions
- **Flutter SDK**: `3.29.3` (Channel `stable`)
- **Dart SDK**: `3.7.2` (`sdk: ^3.7.2` in `pubspec.yaml`)
- **CocoaPods**: `1.16.2+` (for iOS / macOS pods)
- **Java**: OpenJDK `17+`
- **Xcode**: `15.0+` (for iOS / macOS builds)
- **Android Studio / SDK**: Android API level 21+ (Min SDK 21, Target SDK 34)

---

## 2. Installation & Getting Started

### Step 1: Verify Flutter Environment
Ensure that Flutter 3.29.3 is properly installed and added to your `PATH`:
```bash
flutter --version
flutter doctor -v
```

> [!TIP]
> If you are using `fvm` (Flutter Version Management):
> ```bash
> fvm use 3.29.3
> ```

### Step 2: Clone & Navigate to Project
```bash
git clone <repository-url>
cd project
```

### Step 3: Install Dependencies
Fetch all required Dart and Flutter dependencies:
```bash
flutter pub get
```

### Step 4: iOS & macOS Pod Installation (Apple platforms only)
If developing on macOS for iOS or macOS Desktop targets:
```bash
# For iOS
cd ios && pod install && cd ..

# For macOS
cd macos && pod install && cd ..
```

---

## 3. Running the Application

### List Connected Devices & Simulators
```bash
flutter devices
```

### Run in Debug Mode
Select your target device or let Flutter auto-detect:
```bash
# Auto-detect target device
flutter run

# Run on Android emulator / physical device
flutter run -d android

# Run on iOS Simulator / physical device
flutter run -d ios

# Run on macOS Desktop
flutter run -d macos
```

### Run in Release / Profile Mode
```bash
flutter run --release
# or
flutter run --profile
```

### Building Application Bundles

#### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle (AAB)
flutter build appbundle --release
```

#### iOS
```bash
flutter build ipa --release
```

#### macOS Desktop
```bash
flutter build macos --release
```

---

## 4. Automated Tests & Static Analysis

### Run Unit Test Suite
The test suite in `test/vault_security_test.dart` covers mandatory assignment test cases:
1. **AES Round-Trip & Nonce Uniqueness**: Verifies AES-256-GCM encryption/decryption round-trip, tag verification on tampered data, and asserts that two encryptions of identical payloads produce unique ciphertexts.
2. **PIN Verification**: Verifies correct PIN passes, wrong PIN fails, and stored hash is neither raw PIN nor unsalted SHA-256 (PBKDF2-HMAC-SHA256 with 100k iterations).
3. **Single-Flight 401 Interceptor**: Simulates concurrent 401 requests and asserts exactly 1 `/auth/refresh` call is made before retrying and resolving all queued requests.

```bash
flutter test
```

### Run Dart Analyzer & Code Quality Checks
```bash
# Analyze code for warnings and lint errors
dart analyze
# or
flutter analyze

# Verify code formatting
dart format --output=none --set-exit-if-changed .
```

---

## 5. Architecture (MVVM + 3-Layer Clean Architecture)

The codebase strictly enforces clean separation of concerns across three distinct layers:

```
lib/
├── core/                         # Cryptography, Theme, Security Services & Utils
│   ├── constants/                # App colors and API endpoints
│   ├── security/
│   │   ├── aes_gcm_service.dart          # AES-256-GCM AEAD encryption & tag verification
│   │   ├── pin_hasher.dart               # PBKDF2-HMAC-SHA256 (100k iters) & constant-time compare
│   │   ├── root_jailbreak_service.dart   # Root / Jailbreak / Developer compromise check
│   │   └── screen_privacy_service.dart   # Anti-screenshot (FLAG_SECURE) & iOS privacy blur
│   ├── theme/                    # Light & Dark themes matching design specifications
│   └── utils/                    # Error formatter & relative time formatter
│
├── data/                         # Data Sources, Models, Interceptors, Repository Impls
│   ├── datasources/
│   │   ├── auth_remote_datasource.dart   # Dio client communicating with DummyJSON
│   │   ├── secure_storage_datasource.dart# Hardware Keychain/Keystore via flutter_secure_storage
│   │   ├── encrypted_file_datasource.dart# AES-256-GCM disk cache read/write
│   │   └── preferences_datasource.dart   # Non-sensitive SharedPreferences (intro seen, theme)
│   ├── interceptors/
│   │   └── auth_interceptor.dart         # Single-flight 401 token refresh & retry queue
│   ├── models/                           # User & Token models
│   └── repositories/                     # Concrete repository implementations
│
├── domain/                       # Domain Contracts
│   └── repositories/                     # AuthRepository, ProfileRepository, PinRepository
│
└── presentation/                 # Presentation Layer (MVVM)
    ├── viewmodels/                       # BLoC / Cubits (Splash, Login, Profile, Settings, PIN, Theme)
    ├── views/                            # 8 Pixel-Perfect Screens
    │   ├── splash/splash_screen.dart
    │   ├── intro/intro_screen.dart
    │   ├── auth/login_screen.dart
    │   ├── profile/profile_screen.dart   # Online & Offline encrypted cache views
    │   ├── settings/settings_screen.dart
    │   ├── pin/set_pin_screen.dart       # Step 1 & Step 2 PIN creation
    │   ├── pin/pin_lock_screen.dart      # Lockout barrier with attempt limiting
    │   └── security/device_compromised_screen.dart
    └── widgets/                          # Numeric keypad, PIN dots, Session timer chip, Offline banner
```

---

## 6. Security Highlights

### Authenticated Encrypted Cache (AES-256-GCM)
* **Master Key**: Random 256-bit key dynamically generated on first launch using `Random.secure()` and securely stored in hardware-backed KeyStore/Keychain via `flutter_secure_storage`.
* **Random Nonce / IV**: Fresh 12-byte (96-bit) nonce generated on **every single write**. Encrypting identical payloads produces completely different ciphertext files.
* **Integrity Tag**: 128-bit authentication tag appended to the ciphertext. Tampered data fails authentication tag validation and is treated gracefully as a **cache miss** without throwing crashes.

### App Lock PIN (PBKDF2-HMAC-SHA256)
* **Key Derivation**: 100,000 iterations of HMAC-SHA256 with a 16-byte cryptographically secure random salt.
* **Storage**: Only the 16-byte random salt and 256-bit derived hash are stored in `flutter_secure_storage`. The raw PIN is never saved.
* **Timing-Attack Resistance**: Verification uses constant-time byte-by-byte comparison (`constantTimeEquals`).
* **Attempt Limiting**: Tracks wrong attempts; the 3rd consecutive failed attempt initiates an immediate complete session wipe and forced logout.
* **Lifecycle Observer**: Full-screen PIN barrier intercepts app return from background (`AppLifecycleState.resumed`).

### Token Lifecycle & Single-Flight Concurrency
* Logs in with mandatory `expiresInMins: 1`.
* When `/auth/me` returns `401 Unauthorized`, `AuthInterceptor` intercepts the call, creates a single-flight mutex/completer, executes exactly **one** `/auth/refresh` request, updates stored tokens, and retries all concurrent queued requests.
* If refresh fails, wipes all credentials and routes to the Login screen.

### Root / Jailbreak & Anti-Screenshot Protection
* Detects rooted/jailbroken devices on startup and blocks access.
* Disables screenshot and screen recording capture (`FLAG_SECURE` on Android) and blurs task snapshots in the iOS App Switcher.

---

## 7. Declaration

No generative AI was used in this submission.
Signed: Anup Singh, 2026-09-10
