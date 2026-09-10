# VAULT — Secure Session & Encrypted Storage Demo

A production-ready Flutter application built for the **Secure Session & Encrypted Storage** assignment. Integrates with the public DummyJSON Auth API and demonstrates hardened local cryptography, single-flight token interceptor management, PBKDF2 PIN app lock, root/jailbreak detection, and anti-screenshot privacy protection.

---

## 1. Architecture (MVVM + 3-Layer Clean Architecture)

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

## 2. Security Highlights

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

## 3. Automated Unit Tests (Exactly 3 Tests)

The test suite in `test/vault_security_test.dart` covers the 3 mandatory assignment test cases:
1. **AES Round-Trip & Nonce Uniqueness**: Verifies encryption/decryption round-trip, tag verification on tampered data, and asserts that two encryptions of identical payloads differ.
2. **PIN Verification**: Verifies correct PIN passes, wrong PIN fails, and stored hash is neither raw PIN nor unsalted SHA-256.
3. **Single-Flight 401 Interceptor**: Simulates 3 concurrent requests returning 401 and asserts exactly 1 `/auth/refresh` call is made before retrying and resolving all 3 requests.

Run tests:
```bash
flutter test
```

Run analyzer:
```bash
dart analyze
```

---

## 4. Declaration

No generative AI was used in this submission.
Signed: Anup Singh, 2026-09-10
