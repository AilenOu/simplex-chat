# SimpleX Chat Android Build Error - Complete Resolution Guide

## Problem Summary

Your Android build is failing because it cannot find the native Haskell libraries:

```
ninja: error: 'D:/works/git/simplex-chat/apps/multiplatform/common/src/commonMain/cpp/android/libs/x86_64/libsimplex.so', needed by '...libapp-lib.so', missing and no known rule to make it
```

## Root Cause

SimpleX Chat is built with **Haskell** for the core chat logic. Android apps require this compiled as native shared libraries (`.so` files). These libraries:

1. **Cannot be built by Gradle/CMake** - They require the Haskell compiler (GHC) and cross-compilation toolchain
2. **Must be pre-built** using Nix (a package manager with cross-compilation support)
3. **Must be placed** in the correct directory structure before the Android build begins

## Quick Solutions by Operating System

### 🪟 Windows

**Easiest Method: Docker**

```powershell
# From project root
.\Build-AndroidNativeLibs.ps1 -Method docker -ABI arm64-v8a

# Takes 30-60 minutes on first run
# Subsequent builds are faster due to caching
```

**Alternative: WSL2**

```powershell
# Check prerequisites
.\Build-AndroidNativeLibs.ps1 -Method check

# Build with WSL2
.\Build-AndroidNativeLibs.ps1 -Method wsl2 -ABI arm64-v8a
```

### 🐧 Linux & 🍎 macOS

**Using Nix (Recommended)**

```bash
# Build the libraries
./scripts/android/build-android.sh arm64-v8a

# Or locally
./scripts/build-android-local.sh debug arm64-v8a
```

**Nix not installed?**

```bash
# Install Nix first
curl -sSf https://releases.nixos.org/nix/nix-2.22.0/install | sh

# Then run the build script
./scripts/android/build-android.sh
```

## What Happens During Build

### Step 1: Native Library Compilation (20-60 minutes)
```
Nix builds two libraries:

libsimplex.so (5-8 MB)
├─ Source: src/Simplex/Chat/ (Haskell)
├─ Compiled with: GHC + Android NDK
└─ Contains: Chat protocol, encryption, database logic

libsupport.so (500 KB)
├─ Source: android-support repository
├─ Compiled with: Android NDK C compiler
└─ Contains: Android JNI support functions
```

### Step 2: Library Extraction (automatic)
```
Nix output zip files are extracted to:

libs/
├── arm64-v8a/          ← 64-bit ARM (modern devices)
│   ├── libsimplex.so
│   ├── libsupport.so
│   └── dependencies (libssl, libcrypto, libgmp, etc.)
├── armeabi-v7a/        ← 32-bit ARM (older devices)
│   └── ... same files ...
└── x86_64/             ← Intel x86 (emulators)
    └── ... same files ...
```

### Step 3: Android Build (5-15 minutes)
```
Gradle/CMake finds the libraries and builds:

libapp-lib.so (C wrapper linking native libraries)
  ↓
android.apk (final app package)
```

## Architecture Selection

Choose based on your use case:

| ABI | Recommended For | Build Time | Market Share |
|-----|-----------------|-----------|--------------|
| **arm64-v8a** | Production, modern devices | 25-35 min | ~90% |
| **armeabi-v7a** | Older device support | 25-35 min | ~10% |
| **x86_64** | Testing on emulator | 15-20 min | ~0% |
| **all** | Production release | 60-90 min | All |

**For Development**: Build `arm64-v8a` only (fastest)
**For Release**: Build `all` architectures (or `arm64-v8a` + `armeabi-v7a`)

## Next Steps After Building Libraries

Once the native libraries are built, continue with Android development:

```bash
cd apps/multiplatform

# Build debug APK
./gradlew assembleDebug

# Install on connected device
adb install -r android/build/outputs/apk/debug/android-arm64-v8a-debug.apk

# Or build release APK
./gradlew assembleRelease
```

## Detailed Guides by Topic

### 📖 For Understanding the Error
→ Read: `CMAKE_BUILD_GUIDE.md`

Explains:
- How CMake discovers the libraries
- Why Ninja can't build them
- Dependency graphs
- Troubleshooting checklist

### 📖 For Step-by-Step Build Instructions
→ Read: `ANDROID_NATIVE_BUILD_GUIDE.md`

Covers:
- All build methods (Nix, Docker, manual)
- Supported architectures
- Build time estimates
- Windows-specific guidance

### 📖 For Quick First-Time Fix
→ Read: `ANDROID_QUICK_FIX.md`

Contains:
- One-command solutions
- Status checks
- Architecture selection guide
- Common problems & fixes

## Common Issues & Solutions

### 1. "Docker not found"
```powershell
# Install Docker Desktop
# https://www.docker.com/products/docker-desktop
# Then restart the script
```

### 2. "WSL2 not installed"
```powershell
# In Administrator PowerShell
wsl --install
# Restart computer
```

### 3. "Build timeout / Out of memory"
```bash
# Ensure at least 10 GB free disk space
# Reduce parallel jobs: -Dorg.gradle.workers.max=2
# Try again - Nix will use cache
```

### 4. "Libraries still missing after build"
```bash
# Verify files exist
ls -l apps/multiplatform/common/src/commonMain/cpp/android/libs/arm64-v8a/

# Check file type (should be ELF shared object)
file libs/arm64-v8a/libsimplex.so

# Rebuild if necessary
./Build-AndroidNativeLibs.ps1 -Method docker -ABI arm64-v8a
```

### 5. "Need to build additional ABIs"
```bash
# Build another architecture
./Build-AndroidNativeLibs.ps1 -Method docker -ABI armeabi-v7a

# Now rebuild Android for multiple ABIs
./gradlew clean :android:assembleRelease
```

## Files Provided to Help You

This project now includes comprehensive documentation:

1. **`ANDROID_QUICK_FIX.md`** - Start here! Quick one-command solutions
2. **`ANDROID_NATIVE_BUILD_GUIDE.md`** - Complete step-by-step guide
3. **`CMAKE_BUILD_GUIDE.md`** - Technical deep dive into the error
4. **`Build-AndroidNativeLibs.ps1`** - Windows PowerShell helper script
5. **`ANDROID_BUILD_COMPLETION.md`** - CI/CD setup documentation

## Build System Architecture

```
SimpleX Chat Project
│
├─ Haskell Source Code (src/)
│  └─ Compiled by: GHC (Glasgow Haskell Compiler)
│     └─ Output: libsimplex.so
│
├─ Android Native Code (cpp/)
│  ├─ C Wrapper (simplex-api.c)
│  └─ Compiled by: Android NDK Clang
│     └─ Links to: libsimplex.so
│        Output: libapp-lib.so
│
├─ Kotlin/Android Code (kotlin/)
│  └─ Compiled by: Android Gradle
│     └─ Links to: libapp-lib.so
│        Output: chat.simplex.app.apk
│
└─ Cross-Compilation Support
   ├─ Nix Flakes (flake.nix) - Orchestrates build
   ├─ Gradle (Android) - Final packaging
   └─ CMake - Native compilation
```

## Performance Tips

### First-Time Build
- Takes 45-90 minutes depending on system and ABI count
- Downloads all dependencies
- Compiles Haskell code from scratch

### Subsequent Builds
- Much faster (10-30 minutes) with Nix cache
- Use `-Dorg.gradle.parallel=true` for faster Gradle
- Build single ABI during development

### Speed Optimization
```bash
# Use ccache for faster builds
export CCACHE_DIR=~/.ccache

# Enable parallel compilation
export GRADLE_OPTS="-Xmx4g -Dorg.gradle.parallel=true"

# Limit workers if low on RAM
-Dorg.gradle.workers.max=2
```

## Dependency Overview

| Layer | Component | Built By | Output |
|-------|-----------|----------|--------|
| **Haskell** | simplex-chat library | Nix + GHC | libsimplex.so |
| **Support** | android-support | Nix + NDK | libsupport.so |
| **Native** | simplex-api.c wrapper | Gradle + CMake | libapp-lib.so |
| **App** | Kotlin/Compose code | Gradle | .apk |

## Getting More Help

### Quick Check
```powershell
.\Build-AndroidNativeLibs.ps1 -Method check
```
Shows what's installed and ready

### View Logs
- **Gradle logs**: `android/build/outputs/logs/`
- **CMake logs**: `android/build/intermediates/cxx/*/build.log`
- **Docker logs**: Check Docker Desktop logs

### Manual Build (for debugging)
```bash
# See exactly what's being done
./scripts/android/build-android.sh -v

# Or with Nix directly
nix build '.#aarch64-android:lib:simplex-chat' --log-format internal-json
```

## Success Indicators

After running the build script, you should have:

```bash
# ✅ Libraries built and extracted
ls libs/arm64-v8a/libsimplex.so    # File exists
ls libs/arm64-v8a/libsupport.so    # File exists

# ✅ File type is correct
file libs/arm64-v8a/libsimplex.so
# Output: ELF 64-bit LSB shared object

# ✅ File size is reasonable
ls -lh libs/arm64-v8a/libsimplex.so
# Size: 5-8 MB
```

Then the Android build should work:
```bash
./gradlew assembleDebug
# ✅ Build successful
```

## Environment Recommendations

### Windows
- Docker Desktop (8+ GB RAM)
- OR WSL2 with Nix
- JDK 17+
- Android SDK 35

### macOS
- Nix installed
- JDK 17+
- Android SDK 35

### Linux
- Nix installed (or Docker)
- GCC/Clang toolchain
- JDK 17+
- Android SDK 35

## Next Steps

1. **Immediate**: Run the quick fix
   ```powershell
   .\Build-AndroidNativeLibs.ps1 -Method docker -ABI arm64-v8a
   ```

2. **Monitor**: Check build progress in console output

3. **Wait**: 30-60 minutes for first build

4. **Verify**: Check that `libs/arm64-v8a/` contains the `.so` files

5. **Build**: Continue with Android development
   ```bash
   ./gradlew assembleDebug
   ```

---

**For detailed information, see the guide files listed above.**

**Last Updated**: 2026-04-22

