# SimpleX Chat Android Build Architecture - Visual Guide

## The Error Explained Visually

```
┌─────────────────────────────────────────────────────────────────┐
│                   Android Build Process                          │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Step 1: Gradle reads build configuration               │   │
│  │ ├─ Detects externalNativeBuild -> CMake               │   │
│  │ └─ Detects Java/Kotlin source files                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                            ↓                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Step 2: CMake builds C wrapper (simplex-api.c)        │   │
│  │ ├─ Looks for: libsimplex.so                           │   │
│  │ ├─ Looks for: libsupport.so                           │   │
│  │ └─ Location: libs/{ABI}/ (relative to CMakeLists.txt) │   │
│  └─────────────────────────────────────────────────────────┘   │
│                            ↓                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Step 3: Ninja (low-level build tool) creates link cmd │   │
│  │ ├─ Links: libapp-lib.so (C wrapper)                   │   │
│  │ ├─ Needs:  libsimplex.so ✗ NOT FOUND!               │   │
│  │ ├─ Needs:  libsupport.so ✗ NOT FOUND!               │   │
│  │ └─ Error: "missing and no known rule to make it"      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

❌ BUILD FAILS - Missing Native Libraries
```

## What's Missing

```
Expected Directory Structure:

apps/multiplatform/common/src/commonMain/cpp/android/
│
├── CMakeLists.txt (says: look for libs/{ABI}/lib*.so)
├── simplex-api.c (C wrapper code)
│
└── libs/
    ├── arm64-v8a/
    │   ├── ✗ libsimplex.so (MISSING!)
    │   ├── ✗ libsupport.so (MISSING!)
    │   └── ✗ libssl.so.1.1 (and other deps)
    ├── armeabi-v7a/
    │   ├── ✗ libsimplex.so (MISSING!)
    │   └── ...
    └── x86_64/
        ├── ✗ libsimplex.so (MISSING!)
        └── ...

You must provide these .so files!
```

## The Solution Flow

```
┌──────────────────────────────────────────────────────────────┐
│ Building Native Libraries (Haskell → .so)                   │
│                                                              │
│ INPUT:                                                       │
│   src/Simplex/Chat/                (Haskell source)         │
│   android-support/                 (Android JNI code)       │
│                                                              │
│ PROCESS:                                                     │
│   ┌──────────────────────────────────────────────────┐     │
│   │ Nix (Package Manager)                            │     │
│   │  ├─ Installs: GHC (Haskell compiler)            │     │
│   │  ├─ Installs: Android NDK (cross-compiler)      │     │
│   │  ├─ Downloads: Dependencies                      │     │
│   │  └─ Runs: Build commands                         │     │
│   └──────────────────────────────────────────────────┘     │
│              ↓                                               │
│   ┌──────────────────────────────────────────────────┐     │
│   │ Cross-Compilation                                │     │
│   │  ├─ Target: aarch64-unknown-linux-android       │     │
│   │  ├─ Produces: libsimplex.so (for ARM64)         │     │
│   │  ├─ Target: armv7a-unknown-linux-androideabi    │     │
│   │  └─ Produces: libsimplex.so (for ARMv7)         │     │
│   └──────────────────────────────────────────────────┘     │
│              ↓                                               │
│ OUTPUT:                                                      │
│   pkg-aarch64-android-libsimplex.zip                        │
│   pkg-armv7a-android-libsimplex.zip                         │
│   pkg-aarch64-android-libsupport.zip                        │
│   pkg-armv7a-android-libsupport.zip                         │
│                                                              │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│ Extracting Libraries                                         │
│                                                              │
│ unzip pkg-aarch64-android-libsimplex.zip                    │
│      → libs/arm64-v8a/libsimplex.so                         │
│                                                              │
│ unzip pkg-aarch64-android-libsupport.zip                    │
│      → libs/arm64-v8a/libsupport.so                         │
│      → libs/arm64-v8a/libssl.so.1.1                         │
│      → libs/arm64-v8a/libcrypto.so.1.1                      │
│      → ... (and other dependencies)                         │
│                                                              │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│ Building Android App (with native libraries)                 │
│                                                              │
│ Now Gradle/CMake can find the libraries:                    │
│   CMakeLists.txt searches for libs/arm64-v8a/lib*.so        │
│   ✓ libsimplex.so    FOUND!                                │
│   ✓ libsupport.so    FOUND!                                │
│   ✓ Build succeeds!                                         │
│                                                              │
│ OUTPUT:                                                      │
│   libapp-lib.so (C wrapper + linked libraries)              │
│   chat.simplex.app.apk (complete Android app)              │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## Complete Dependency Graph

```
chat.simplex.app.apk (Final APK)
│
├── Kotlin Code
│   └── Calls: C functions in libapp-lib.so
│
├── libapp-lib.so (C wrapper)
│   └── Depends on:
│       ├── libsimplex.so ← THIS IS MISSING!
│       │   ├── Haskell RTS (runtime)
│       │   ├── libffi (foreign function interface)
│       │   ├── libssl.so.1.1 (OpenSSL)
│       │   ├── libcrypto.so.1.1 (OpenSSL crypto)
│       │   └── libgmp.so (Big integers)
│       │
│       └── libsupport.so ← THIS IS MISSING!
│           └── Android C library
│
└── Assets, Resources, Manifest, etc.
```

## Architecture Selection

```
╔═══════════════════════════════════════════════════════════╗
║ Which ABI to Build?                                       ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  arm64-v8a (64-bit ARM)          ████████████████████    ║
║  └─ Modern devices               ~90% of market          ║
║  └─ Recommended: YES              Build time: 25-35 min  ║
║                                                           ║
║  armeabi-v7a (32-bit ARM)        ██                      ║
║  └─ Older devices                ~10% of market          ║
║  └─ Recommended: For release      Build time: 25-35 min  ║
║                                                           ║
║  x86_64 (Intel 64-bit)           █                       ║
║  └─ Emulators, tablets           Dev/testing only        ║
║  └─ Recommended: Testing          Build time: 15-20 min  ║
║                                                           ║
║  x86 (Intel 32-bit)              ░                       ║
║  └─ Legacy emulators             <1% of market           ║
║  └─ Recommended: Not needed       Build time: 15-20 min  ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

Quick Start: Build arm64-v8a only
Production: Build arm64-v8a + armeabi-v7a
Test: Build x86_64
```

## Build Methods Comparison

```
╔════════════════════════════════════════════════════════════╗
║                    WINDOWS BUILD OPTIONS                  ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  METHOD 1: Docker                                          ║
║  ├─ Install Docker Desktop                               ║
║  ├─ Run: .\Build-AndroidNativeLibs.ps1 -Method docker   ║
║  ├─ Time: 45-90 min (first), 20-30 min (cached)        ║
║  ├─ Pros: ✓ Easiest, ✓ No Nix needed                   ║
║  └─ Cons: ✗ Docker overhead                            ║
║                                                            ║
║  METHOD 2: WSL2 + Nix                                     ║
║  ├─ Install WSL2                                          ║
║  ├─ Install Nix in WSL2                                   ║
║  ├─ Run: .\Build-AndroidNativeLibs.ps1 -Method wsl2    ║
║  ├─ Time: 45-90 min (first), 20-30 min (cached)        ║
║  ├─ Pros: ✓ Nix native, ✓ Faster after first build    ║
║  └─ Cons: ✗ Setup required                             ║
║                                                            ║
║  METHOD 3: Pre-built Libraries                            ║
║  ├─ Download from GitHub Releases                         ║
║  ├─ Extract to libs/{ABI}/                               ║
║  ├─ Time: 5 minutes                                        ║
║  ├─ Pros: ✓ Instant                                      ║
║  └─ Cons: ✗ Need to find/download binaries             ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

## Time Breakdown

```
┌────────────────────────────────────────────────────────┐
│ Total Build Time: ~40-65 minutes (first time)         │
│                                                        │
│ NATIVE LIBRARY BUILD (30-60 min)                      │
│ ├─ Download dependencies:        5-15 min ████░░░░░░ │
│ ├─ Compile Haskell code:        20-40 min █████████░░ │
│ └─ Create .so files:             5-10 min ██░░░░░░░░ │
│                                                        │
│ EXTRACT & SETUP (2-5 min)                             │
│ └─ Unzip and place libraries:    2-5 min  █░░░░░░░░░ │
│                                                        │
│ ANDROID BUILD (5-15 min)                              │
│ ├─ CMake configuration:          1-2 min  ░░░░░░░░░░ │
│ ├─ C wrapper compilation:        2-5 min  ██░░░░░░░░ │
│ ├─ Gradle build:                 2-8 min  ██░░░░░░░░ │
│ └─ APK packaging:                1-2 min  █░░░░░░░░░ │
│                                                        │
│ ═════════════════════════════════════════════════════ │
│ TOTAL (First Run):              40-65 min             │
│                                                        │
│ SUBSEQUENT BUILDS: 15-30 min (with Nix cache)        │
└────────────────────────────────────────────────────────┘
```

## File Location Diagram

```
D:\works\git\simplex-chat\
│
├── [Documentation Files - NEW]
│   ├── ANDROID_QUICK_FIX.md                      ← Start here!
│   ├── ANDROID_NATIVE_BUILD_GUIDE.md             ← Full guide
│   ├── CMAKE_BUILD_GUIDE.md                      ← Technical
│   ├── ANDROID_BUILD_ERROR_RESOLUTION.md         ← Complete ref
│   ├── README_ANDROID_BUILD_RESOURCES.md         ← This summary
│   ├── ANDROID_QUICK_REFERENCE.ps1               ← (Windows)
│   └── Build-AndroidNativeLibs.ps1               ← (Windows)
│
├── [Configuration Files]
│   ├── flake.nix                                 ← Nix config
│   ├── cabal.project                             ← Haskell config
│   └── simplex-chat.cabal                        ← Cabal config
│
├── [Scripts]
│   ├── scripts/
│   │   ├── android/
│   │   │   ├── build-android.sh                  ← Main build
│   │   │   └── compress-and-sign-apk.sh          ← APK signing
│   │   └── build-android-local.sh                ← Local build
│   └── nix/
│       └── [Nix helper scripts]
│
├── apps/
│   └── multiplatform/
│       ├── common/src/commonMain/cpp/android/
│       │   ├── CMakeLists.txt                    ← CMAKE config
│       │   ├── simplex-api.c                     ← C wrapper
│       │   └── libs/                             ← ← ← LIBRARIES GO HERE!
│       │       ├── arm64-v8a/
│       │       │   ├── libsimplex.so             ← ← ← PLACE HERE
│       │       │   └── libsupport.so             ← ← ← PLACE HERE
│       │       ├── armeabi-v7a/
│       │       │   └── ...
│       │       └── x86_64/
│       │           └── ...
│       │
│       ├── android/
│       │   ├── build.gradle.kts                  ← Android config
│       │   └── build/outputs/apk/                ← Output APKs
│       │       ├── debug/
│       │       └── release/
│       │
│       └── [Kotlin/Compose source]
│
└── src/
    ├── Simplex/Chat/                             ← Haskell source
    │   ├── Controller.hs
    │   ├── Types.hs
    │   ├── Store.hs
    │   └── [... 100+ Haskell modules ...]
    │
    └── [... other Haskell modules ...]
```

## Success Flow

```
✅ START
  │
  ├─→ Read: ANDROID_QUICK_FIX.md
  │   └─→ (5 minutes)
  │
  ├─→ Run: Build-AndroidNativeLibs.ps1 or build script
  │   └─→ Builds native libraries (30-60 min)
  │       └─→ Extracts to libs/{ABI}/ (2 min)
  │
  ├─→ Verify: Libraries exist in libs/ directory
  │   └─→ Check: ls libs/arm64-v8a/lib*.so
  │
  ├─→ Build: Android APK
  │   └─→ cd apps/multiplatform && ./gradlew assembleDebug
  │       └─→ (5-15 minutes)
  │
  ├─→ Install: On device or emulator
  │   └─→ adb install -r android/build/outputs/.../app.apk
  │
  └─→ ✅ SUCCESS - App running!
```

---

**Remember**: The native libraries (`libsimplex.so` and `libsupport.so`) are the KEY. Once they're in place in the correct directory, everything else works!

