# Quick Start: Fixing "libsimplex.so missing" Build Error

## The Error You're Seeing

```
C/C++: ninja: error: 'D:/works/git/simplex-chat/apps/multiplatform/common/src/commonMain/cpp/android/libs/x86_64/libsimplex.so', needed by '...libapp-lib.so', missing and no known rule to make it
```

This means the Android build process can't find the native Haskell libraries it needs.

## Quick Solution

### For Windows Users

#### Option 1: Use Docker (Easiest)

```powershell
# In PowerShell, from the project root
.\Build-AndroidNativeLibs.ps1 -Method docker -ABI arm64-v8a

# Or for all architectures
.\Build-AndroidNativeLibs.ps1 -Method docker -ABI all
```

This will:
1. Build a Docker image with Nix
2. Compile the native libraries
3. Extract them to the correct directories
4. Complete in 30-60 minutes

#### Option 2: Use WSL2 (If Installed)

```powershell
# First, install Nix in WSL2 (one-time setup)
wsl -- curl -sSf https://releases.nixos.org/nix/nix-2.22.0/install | sh

# Then build
.\Build-AndroidNativeLibs.ps1 -Method wsl2 -ABI arm64-v8a
```

### For Linux/macOS Users

```bash
# Use the provided script
./scripts/android/build-android.sh arm64-v8a

# Or build locally
./scripts/build-android-local.sh debug arm64-v8a
```

### For Mac with Nix Already Installed

```bash
cd /path/to/simplex-chat

# Build for arm64-v8a (modern devices)
nix build '.#hydraJobs.aarch64-android:lib:simplex-chat'
nix build '.#hydraJobs.aarch64-android:lib:support'

# Extract libraries manually
unzip -o result/pkg-aarch64-android-libsimplex.zip -d \
  apps/multiplatform/common/src/commonMain/cpp/android/libs/arm64-v8a

unzip -o result/pkg-aarch64-android-libsupport.zip -d \
  apps/multiplatform/common/src/commonMain/cpp/android/libs/arm64-v8a
```

## What These Scripts Do

### 1. Build Native Libraries
- Compiles Haskell code to native Android libraries
- Uses GHC (Glasgow Haskell Compiler) with Android NDK
- Creates `.so` (shared object) files

### 2. Extract to Correct Location
```
apps/multiplatform/common/src/commonMain/cpp/android/libs/
├── arm64-v8a/
│   ├── libsimplex.so      ← Core chat library
│   ├── libsupport.so      ← Android support functions
│   └── [other dependencies]
├── armeabi-v7a/
│   ├── libsimplex.so
│   └── libsupport.so
└── x86_64/
    ├── libsimplex.so
    └── libsupport.so
```

### 3. Build Android APK
Once libraries are in place, Gradle can build the APK normally

## Build Time Estimates

| Method | Time (First) | Time (Cached) | Notes |
|--------|-------------|---------------|-------|
| Docker | 45-90 min | 20-30 min | Requires Docker installed |
| WSL2 + Nix | 45-90 min | 20-30 min | Requires Nix setup in WSL2 |
| Linux Nix | 30-60 min | 10-20 min | Fastest if already set up |
| macOS Nix | 45-90 min | 20-30 min | Similar to Linux |

## Check Current Status

```powershell
# Check what libraries you already have
ls D:\works\git\simplex-chat\apps\multiplatform\common\src\commonMain\cpp\android\libs\
```

Output should look like:
```
    Directory: D:\...\libs

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        2024-01-15  10:30 AM                arm64-v8a
d-----        2024-01-15  10:30 AM                armeabi-v7a
```

Each directory should contain:
- `libsimplex.so` (~5-8 MB)
- `libsupport.so` (~500 KB)
- Other OpenSSL dependencies

## If You Already Have Pre-built Libraries

If you downloaded libraries from GitHub Releases or built them on another machine:

1. Extract the ZIP file containing the `.so` files
2. Place them in the appropriate `libs/{ABI}/` directory
3. Run the Android build:

```powershell
cd D:\works\git\simplex-chat\apps\multiplatform
./gradlew assembleDebug
```

## Troubleshooting

### "Docker not found"
Install Docker Desktop: https://www.docker.com/products/docker-desktop

### "WSL2 not found"
Install WSL2:
```powershell
# In PowerShell (Administrator)
wsl --install
# Restart computer
```

### "Build failed / Timeout"
- Ensure you have 10+ GB free disk space
- Check internet connection (downloads dependencies)
- Try again - Nix will use cache on next attempt

### "Libraries still missing after build"
1. Check the build output for errors
2. Verify libraries exist: `ls libs/arm64-v8a/lib*.so`
3. Check file type: `file libs/arm64-v8a/libsimplex.so`
   - Should show: "ELF 64-bit LSB shared object"

## Next Steps After Building

Once libraries are built:

```powershell
# Navigate to Android project
cd D:\works\git\simplex-chat\apps\multiplatform

# Build debug APK
./gradlew assembleDebug

# Or build release APK
./gradlew assembleRelease

# Find APK in:
# android/build/outputs/apk/debug/
# or
# android/build/outputs/apk/release/
```

## Architecture Selection Guide

Choose the ABI based on your use case:

| ABI | Use Case | Market | Build Time |
|-----|----------|--------|------------|
| **arm64-v8a** | Modern Android devices | ~90% | 25-35 min |
| **armeabi-v7a** | Older devices (compatibility) | ~10% | 25-35 min |
| **x86_64** | Emulators, tablets | Testing | 15-20 min |
| **all** | Production release | All | 45-90 min |

For development/testing:
```powershell
# Build only for arm64-v8a (fastest)
.\Build-AndroidNativeLibs.ps1 -Method docker -ABI arm64-v8a
```

For production release:
```powershell
# Build for all production ABIs
.\Build-AndroidNativeLibs.ps1 -Method docker -ABI all
```

## Getting Help

1. **Full Guide**: Read `ANDROID_NATIVE_BUILD_GUIDE.md`
2. **Check Status**: `.\Build-AndroidNativeLibs.ps1 -Method check`
3. **Debug Info**:
   ```powershell
   docker --version
   wsl --version
   java -version
   ```

## For CI/CD Integration

If you want automated builds in GitHub Actions, see:
- `.github/workflows/build-android.yml`
- `.github/workflows/build-android-signed.yml`

These workflows automatically build and package the libraries.

---

**Still stuck?** Check the detailed guide: `ANDROID_NATIVE_BUILD_GUIDE.md`

