# Android Native Library Build Guide

## Problem Description

The Android build fails with:
```
ninja: error: 'D:/works/git/simplex-chat/apps/multiplatform/common/src/commonMain/cpp/android/libs/x86_64/libsimplex.so', needed by '...libapp-lib.so', missing and no known rule to make it
```

This occurs because the native Haskell libraries (`libsimplex.so` and `libsupport.so`) are missing from the `libs/<ABI>/` directories.

## Root Cause

The SimpleX Chat project compiles Haskell code to native Android libraries using **Nix**. These libraries must be built separately from the Android Gradle build and placed in the correct directories before Gradle runs.

### Build Process Overview

1. **Haskell Compilation** (via Nix)
   - Compiles `simplex-chat` Haskell library → `libsimplex.so`
   - Compiles `android-support` Haskell library → `libsupport.so`
   - These are cross-compiled for the target Android ABI

2. **Library Packaging** (via Nix)
   - Libraries are zipped into platform-specific packages
   - Generated as: `pkg-{arch}-android-libsimplex.zip` and `pkg-{arch}-android-libsupport.zip`

3. **Gradle Build** (Android build)
   - Expects to find the unpacked `.so` files in `apps/multiplatform/common/src/commonMain/cpp/android/libs/{ABI}/`
   - CMake links these libraries into the final APK

## Solution: Building Native Libraries

### Option 1: Using Nix (Recommended for Linux/macOS)

If you have **Nix** installed, use the automated build script:

```bash
cd /path/to/simplex-chat

# Build for a single architecture
./scripts/android/build-android.sh

# Or build locally with the local script
./scripts/build-android-local.sh debug arm64-v8a
```

The script automatically:
1. Builds the Haskell libraries via Nix
2. Extracts them to the correct directory
3. Runs the Gradle build

### Option 2: Manual Build Steps

If you don't have Nix installed, you need to manually place the pre-built libraries:

#### Step 1: Obtain Pre-built Libraries

The project provides pre-built libraries through:

1. **GitHub Releases** - Check the latest release for pre-built APKs
2. **Build on a Linux/macOS machine** with Nix installed
3. **Docker** - Build using the provided Docker images

#### Step 2: Extract Libraries for Your ABI

The `.so` files are packaged as zip files. Extract them to:

```
apps/multiplatform/common/src/commonMain/cpp/android/libs/{ABI}/
```

Where `{ABI}` is one of:
- `arm64-v8a` (64-bit ARM, recommended for modern devices)
- `armeabi-v7a` (32-bit ARM, for older devices)
- `x86_64` (Intel x86 64-bit, for emulators)
- `x86` (Intel x86 32-bit, for older emulators)

#### Step 3: Run Android Build

```bash
cd apps/multiplatform
./gradlew assembleDebug
```

### Option 3: Docker Build

The project includes Docker support for building without Nix:

```bash
# Build the Docker image
docker build -f Dockerfile -t simplex-chat-android .

# Run the build
docker run -v $(pwd):/workspace simplex-chat-android \
  /workspace/scripts/android/build-android.sh
```

## Required Libraries

For each ABI, you need:

| Library | Purpose | Notes |
|---------|---------|-------|
| `libsimplex.so` | Core SimpleX Chat Haskell library | Built from `src/Simplex/Chat/` |
| `libsupport.so` | Android support library | Built from `android-support` repo |

Both must be present in the same ABI directory for the build to succeed.

## Supported Architectures

| ABI | Purpose | Status |
|-----|---------|--------|
| `arm64-v8a` | Modern Android devices (>90% market share) | ✅ Fully Supported |
| `armeabi-v7a` | Older Android devices (for compatibility) | ✅ Fully Supported |
| `x86_64` | Emulators and tablets | ✅ Fully Supported |
| `x86` | Older emulators | ✅ Supported |

## Building Only Specific ABIs

### Debug Build (All ABIs)
```bash
cd apps/multiplatform
./gradlew assembleDebug
```

### Debug Build (Specific ABI)
```bash
cd apps/multiplatform
./gradlew assembleDebug -PabiFilter=arm64-v8a
```

### Release Build (Specific ABI)
```bash
cd apps/multiplatform
./gradlew assembleRelease -PabiFilter=arm64-v8a
```

The `build.gradle.kts` automatically filters ABIs based on build type:
- **Debug**: All ABIs (arm64-v8a, armeabi-v7a, x86_64, x86)
- **Release**: Only production ABIs (arm64-v8a, armeabi-v7a)

## Troubleshooting

### Error: "libsimplex.so missing"

**Cause**: Native libraries not found in `libs/` directory

**Solution**:
1. Check if Nix is installed: `nix --version`
2. Run build script: `./scripts/android/build-android.sh`
3. Or manually place pre-built libraries in the correct directory

### Error: "ninja: no rule to make"

**Cause**: CMake can't find the libraries

**Solution**:
1. Verify files exist: `ls apps/multiplatform/common/src/commonMain/cpp/android/libs/arm64-v8a/`
2. Check file permissions: `chmod +x apps/multiplatform/common/src/commonMain/cpp/android/libs/*/lib*.so`
3. Clean and rebuild: `./gradlew clean && ./gradlew assembleDebug`

### Error: "ABI filter doesn't match available libraries"

**Cause**: Built libraries for wrong ABI

**Solution**:
1. Build for correct ABI: `./scripts/android/build-android.sh arm64-v8a`
2. Or adjust the ABI filter in `build.gradle.kts`

## CMake Configuration

The CMake configuration is located in:
```
apps/multiplatform/common/src/commonMain/cpp/android/CMakeLists.txt
```

Key sections:

```cmake
# Define where libraries are located (relative to CMakeLists.txt)
add_library( simplex SHARED IMPORTED )
set_target_properties( simplex PROPERTIES IMPORTED_LOCATION
    ${CMAKE_SOURCE_DIR}/libs/${ANDROID_ABI}/libsimplex.so)

add_library( support SHARED IMPORTED )
set_target_properties( support PROPERTIES IMPORTED_LOCATION
    ${CMAKE_SOURCE_DIR}/libs/${ANDROID_ABI}/libsupport.so)

# Link them to the app library
target_link_libraries(app-lib simplex support ${log-lib})
```

The `${ANDROID_ABI}` variable is automatically set by Gradle based on the build configuration.

## Native Library Architecture

### libsimplex.so

- **Source**: Haskell code in `src/Simplex/Chat/`
- **Build Flag**: Compiled with `client_library=true` in Nix
- **Size**: ~5-8 MB per ABI (varies with optimization)
- **Dependencies**: libffi, OpenSSL, GMP, Haskell RTS

### libsupport.so

- **Source**: External `android-support` repository
- **Build Flag**: Compiled as shared library in Nix
- **Size**: ~500KB per ABI
- **Purpose**: Android-specific JNI support functions

## Build Time Estimates

| ABI | Time (First Build) | Time (Cached) |
|-----|-------------------|---------------|
| arm64-v8a | 20-30 minutes | 5-10 minutes |
| armeabi-v7a | 20-30 minutes | 5-10 minutes |
| x86_64 | 15-20 minutes | 3-5 minutes |
| All ABIs | 45-90 minutes | 15-30 minutes |

Times are approximate and depend on:
- CPU cores available
- RAM available
- Network speed (for downloading dependencies)
- System load

## Nix Setup

If you need to build with Nix:

### Installation

```bash
# Linux/macOS
curl -sSf https://releases.nixos.org/nix/nix-2.22.0/install | sh

# Or using your package manager
brew install nix  # macOS
```

### Configuration

Edit `~/.config/nix/nix.conf`:
```
experimental-features = nix-command flakes
max-jobs = auto
```

### Verify Installation

```bash
nix flake show
```

This should list all available build targets including `aarch64-android:lib:simplex-chat`, etc.

## Integration with CI/CD

For GitHub Actions, the pre-configured workflows handle library building:

1. **`.github/workflows/build-android.yml`** - Basic build
2. **`.github/workflows/build-android-signed.yml`** - Signed release build

These workflows run on Linux with Nix installed and automatically:
1. Build the native libraries
2. Extract them to the correct directories
3. Run the Gradle build
4. Package the APK

## For Windows Developers

Building native Haskell libraries on Windows requires either:

1. **Use WSL2** with Nix installed in the WSL2 environment
2. **Use Docker** to run the build in a Linux container
3. **Use a Linux/macOS machine** to build the libraries, then copy the `.so` files

Example with WSL2:
```powershell
# In PowerShell
wsl -- bash /path/to/simplex-chat/scripts/android/build-android.sh
```

## Additional Resources

- **Haskell.Nix**: https://github.com/input-output-hk/haskell.nix
- **Android NDK**: https://developer.android.com/ndk
- **CMake Android**: https://developer.android.com/studio/projects/add-native-code
- **Nix Manual**: https://nixos.org/manual/nix/stable/

## FAQ

**Q: Can I build without Nix?**
A: Not directly, but you can use pre-built binaries from GitHub Releases or use Docker.

**Q: How long does the build take?**
A: First build: 45-90 minutes for all ABIs. Subsequent builds with Nix cache: 15-30 minutes.

**Q: Can I build only for arm64-v8a?**
A: Yes, specify the architecture: `./scripts/android/build-android.sh arm64-v8a`

**Q: How do I verify the libraries are correct?**
A: Check file type: `file libs/arm64-v8a/libsimplex.so` should show "ELF 64-bit LSB shared object"

**Q: What if the build fails?**
A: Check the build log for errors, ensure you have enough disk space, and try cleaning: `nix flake update && rm -rf dist-newstyle`

