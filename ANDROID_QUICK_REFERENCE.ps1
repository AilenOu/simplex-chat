#!/usr/bin/env powershell
<#
.SYNOPSIS
Quick reference commands for SimpleX Chat Android native library builds

.NOTES
Run this script with: .\ANDROID_QUICK_REFERENCE.ps1 -ShowAll
Or view specific sections interactively
#>

param(
    [switch]$ShowAll,
    [ValidateSet('windows', 'linux', 'macos', 'error', 'architectures', 'troubleshoot', 'all')]
    [string]$Section = 'all'
)

$quickRef = @{
    'error' = @{
        title = '❌ THE ERROR YOU\''RE SEEING'
        content = @'
ninja: error: 'D:/works/git/simplex-chat/apps/multiplatform/common/src/commonMain/cpp/android/libs/x86_64/libsimplex.so'
needed by '...libapp-lib.so', missing and no known rule to make it

WHAT IT MEANS:
  The Haskell native library (libsimplex.so) is missing
  You cannot build the APK without this library

WHY IT HAPPENS:
  SimpleX Chat core is written in Haskell
  Must be cross-compiled to Android with Nix
  Cannot be built by standard Gradle/CMake
'@
    }

    'windows' = @{
        title = '🪟 WINDOWS - QUICK SOLUTIONS'
        content = @'
FASTEST (Docker):
  .\Build-AndroidNativeLibs.ps1 -Method docker -ABI arm64-v8a
  ⏱️ Time: 30-60 minutes (first run)
  ✅ Best if: Docker Desktop installed

ALTERNATIVE (WSL2):
  .\Build-AndroidNativeLibs.ps1 -Method wsl2 -ABI arm64-v8a
  ⏱️ Time: 30-60 minutes (first run)
  ✅ Best if: WSL2 + Nix installed

CHECK WHAT YOU HAVE:
  .\Build-AndroidNativeLibs.ps1 -Method check

BUILD OTHER ARCHITECTURES:
  .\Build-AndroidNativeLibs.ps1 -Method docker -ABI armeabi-v7a
  .\Build-AndroidNativeLibs.ps1 -Method docker -ABI x86_64
  .\Build-AndroidNativeLibs.ps1 -Method docker -ABI all
'@
    }

    'linux' = @{
        title = '🐧 LINUX - QUICK SOLUTIONS'
        content = @'
WITH NIX INSTALLED:
  ./scripts/android/build-android.sh arm64-v8a
  ⏱️ Time: 30-60 minutes (first run)
  ✅ Fastest method on Linux

LOCAL BUILD:
  ./scripts/build-android-local.sh debug arm64-v8a
  ⏱️ Time: 25-35 minutes
  ✅ After local setup

INSTALL NIX (if needed):
  curl -sSf https://releases.nixos.org/nix/nix-2.22.0/install | sh

BUILD ALL ARCHITECTURES:
  ARCHES="aarch64 armv7a" ./scripts/android/build-android.sh
  ⏱️ Time: 60-90 minutes
'@
    }

    'macos' = @{
        title = '🍎 MACOS - QUICK SOLUTIONS'
        content = @'
WITH NIX INSTALLED:
  ./scripts/android/build-android.sh arm64-v8a
  ⏱️ Time: 30-60 minutes (first run)
  ✅ Recommended method

INSTALL NIX (if needed):
  brew install nix
  # OR manually
  curl -sSf https://releases.nixos.org/nix/nix-2.22.0/install | sh

BUILD FOR SPECIFIC ABI:
  nix build '.#aarch64-android:lib:simplex-chat'
  nix build '.#aarch64-android:lib:support'
  # Extract manually to libs/arm64-v8a/

VERIFY INSTALLATION:
  nix flake show
  # Should list: aarch64-android:lib:simplex-chat, etc.
'@
    }

    'architectures' = @{
        title = '📱 ARCHITECTURE SELECTION GUIDE'
        content = @'
arm64-v8a (64-bit ARM)
  ├─ Market: ~90% of Android devices
  ├─ Use for: Production releases
  ├─ Build time: 25-35 minutes
  └─ Recommended: YES ✅

armeabi-v7a (32-bit ARM)
  ├─ Market: ~10% of older devices
  ├─ Use for: Compatibility
  ├─ Build time: 25-35 minutes
  └─ Recommended: For production

x86_64 (Intel 64-bit)
  ├─ Market: Emulators, tablets
  ├─ Use for: Testing/development
  ├─ Build time: 15-20 minutes
  └─ Recommended: For testing only

x86 (Intel 32-bit)
  ├─ Market: Old emulators
  ├─ Use for: Legacy testing
  ├─ Build time: 15-20 minutes
  └─ Recommended: Not needed

FOR QUICK DEVELOPMENT:
  Build arm64-v8a only
  (saves ~30 minutes per build)

FOR PRODUCTION RELEASE:
  Build arm64-v8a + armeabi-v7a
  (covers 99%+ of devices)

FOR CI/CD:
  Build all 4 architectures
'@
    }

    'troubleshoot' = @{
        title = '🔧 TROUBLESHOOTING'
        content = @'
PROBLEM: "Docker not found"
SOLUTION: Install Docker Desktop
  https://www.docker.com/products/docker-desktop

PROBLEM: "WSL2 not installed"
SOLUTION: In Administrator PowerShell:
  wsl --install
  # Then restart computer

PROBLEM: "Build timeout / Out of memory"
SOLUTION:
  • Ensure 10+ GB free disk space
  • Kill other apps to free RAM
  • Try again (Nix uses cache)

PROBLEM: "Libraries still missing after build"
SOLUTION:
  # Check files exist
  ls apps/multiplatform/common/src/commonMain/cpp/android/libs/arm64-v8a/

  # Verify file type
  file libs/arm64-v8a/libsimplex.so
  # Should show: ELF 64-bit LSB shared object

  # Rebuild if needed
  .\Build-AndroidNativeLibs.ps1 -Method docker -ABI arm64-v8a

PROBLEM: "Nix not found" (Linux/macOS)
SOLUTION:
  curl -sSf https://releases.nixos.org/nix/nix-2.22.0/install | sh
  source $HOME/.nix-profile/etc/profile.d/nix.sh
  nix --version

PROBLEM: "Build is very slow"
SOLUTION:
  • First builds take 45-90 minutes (normal!)
  • Second builds use cache: 10-30 minutes
  • Enable parallel: -Dorg.gradle.parallel=true
  • Use SSD if available

PROBLEM: "Need to rebuild for different ABI"
SOLUTION:
  .\Build-AndroidNativeLibs.ps1 -Method docker -ABI armeabi-v7a
  # Then rebuild Android APK:
  ./gradlew clean :android:assembleRelease
'@
    }

    'after_build' = @{
        title = '✅ AFTER BUILDING NATIVE LIBRARIES'
        content = @'
VERIFY LIBRARIES EXIST:
  ls apps/multiplatform/common/src/commonMain/cpp/android/libs/*/lib*.so

BUILD ANDROID APK:
  cd apps/multiplatform
  ./gradlew assembleDebug

  # Or specific ABI
  ./gradlew assembleDebug -PabiFilter=arm64-v8a

INSTALL ON DEVICE:
  adb install -r android/build/outputs/apk/debug/android-arm64-v8a-debug.apk

FIND APK FILE:
  # Debug APK
  apps/multiplatform/android/build/outputs/apk/debug/

  # Release APK
  apps/multiplatform/android/build/outputs/apk/release/

SIGN APK FOR RELEASE:
  # Use the compress-and-sign-apk.sh script
  ./scripts/android/compress-and-sign-apk.sh \
    9 output_dir sdk_dir keystore_file keystore_pass key_alias key_pass
'@
    }

    'file_locations' = @{
        title = '📁 IMPORTANT FILE LOCATIONS'
        content = @'
PROJECT STRUCTURE:
  D:\works\git\simplex-chat\
  ├── flake.nix                      ← Nix build config
  ├── CMakeLists.txt                 ← For IDE
  ├── Build-AndroidNativeLibs.ps1    ← Windows helper script
  ├── ANDROID_QUICK_FIX.md           ← Quick start guide
  ├── ANDROID_NATIVE_BUILD_GUIDE.md  ← Detailed guide
  ├── CMAKE_BUILD_GUIDE.md           ← Technical details
  ├── ANDROID_BUILD_ERROR_RESOLUTION.md ← This error explained
  └── apps/multiplatform/
      ├── common/src/commonMain/cpp/android/
      │   ├── CMakeLists.txt         ← Where libraries are found
      │   ├── simplex-api.c          ← C wrapper code
      │   └── libs/                  ← PUT LIBRARIES HERE!
      │       ├── arm64-v8a/         ← For arm64
      │       ├── armeabi-v7a/       ← For armv7
      │       └── x86_64/            ← For x86_64
      ├── android/
      │   ├── build.gradle.kts       ← Gradle config
      │   └── build/outputs/apk/     ← Output APKs
      └── scripts/
          ├── build-android.sh       ← Main build script
          └── build-android-local.sh ← Local build script

DOCUMENTATION:
  • ANDROID_QUICK_FIX.md - START HERE
  • ANDROID_NATIVE_BUILD_GUIDE.md - Complete guide
  • CMAKE_BUILD_GUIDE.md - Technical deep dive
  • ANDROID_BUILD_COMPLETION.md - CI/CD setup
'@
    }

    'timing' = @{
        title = '⏱️ BUILD TIME ESTIMATES'
        content = @'
ARCHITECTURE BUILD TIMES:
  arm64-v8a         25-35 minutes
  armeabi-v7a       25-35 minutes
  x86_64            15-20 minutes
  x86               15-20 minutes

TOTAL BUILD TIMES (including Android):
  Single ABI        35-50 minutes
  Two ABIs          60-80 minutes
  Four ABIs         90-120 minutes
  With Android app  +5-15 minutes

FIRST RUN OVERHEAD:
  Download dependencies    15-30 minutes
  Build from source        45-90 minutes
  Nix cache setup          ~5 minutes

CACHED BUILDS (subsequent):
  Single ABI        10-20 minutes
  Four ABIs         30-45 minutes

OPTIMIZATION:
  • Use -Dorg.gradle.parallel=true
  • Limit workers: -Dorg.gradle.workers.max=4
  • Use fast SSD storage
  • Don't run other heavy tasks

ANDROID BUILD ONLY (after libraries):
  Debug APK         5-10 minutes
  Release APK       8-15 minutes
'@
    }

    'help' = @{
        title = '❓ GETTING HELP'
        content = @'
THIS FILE:
  View specific section: .\ANDROID_QUICK_REFERENCE.ps1 -Section windows
  View all: .\ANDROID_QUICK_REFERENCE.ps1 -ShowAll

DETAILED GUIDES:
  • ANDROID_QUICK_FIX.md              → 5-minute fix
  • ANDROID_NATIVE_BUILD_GUIDE.md     → Complete guide
  • CMAKE_BUILD_GUIDE.md              → Technical deep dive
  • ANDROID_BUILD_ERROR_RESOLUTION.md → Error explained

HELPER SCRIPTS:
  .\Build-AndroidNativeLibs.ps1 -Method check
  # Shows what you have installed

COMMAND REFERENCE:
  Docker method:   .\Build-AndroidNativeLibs.ps1 -Method docker -ABI arm64-v8a
  WSL2 method:     .\Build-AndroidNativeLibs.ps1 -Method wsl2 -ABI arm64-v8a
  Check status:    .\Build-AndroidNativeLibs.ps1 -Method check

MANUAL COMMANDS:
  Linux/macOS:     ./scripts/android/build-android.sh arm64-v8a
  After building:  cd apps/multiplatform && ./gradlew assembleDebug

LOG FILES:
  • Gradle logs:     android/build/outputs/logs/
  • CMake logs:      android/build/intermediates/cxx/*/build.log
  • Build console:   Check terminal output during build

VERIFY LIBRARIES:
  ls -lh apps/multiplatform/common/src/commonMain/cpp/android/libs/arm64-v8a/
'@
    }
}

function Show-Section {
    param([string]$key)

    if ($quickRef.ContainsKey($key)) {
        $section = $quickRef[$key]
        Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
        Write-Host $section.title -ForegroundColor Cyan -NoNewline
        Write-Host " " + ("=" * (80 - $section.title.Length)) -ForegroundColor Cyan
        Write-Host $section.content
        Write-Host ("=" * 80) -ForegroundColor Cyan
    }
}

function Show-Menu {
    Write-Host "`nAvailable Sections:" -ForegroundColor Cyan
    Write-Host "  1. error              - Understand the error"
    Write-Host "  2. windows            - Windows solutions"
    Write-Host "  3. linux              - Linux solutions"
    Write-Host "  4. macos              - macOS solutions"
    Write-Host "  5. architectures      - Choose your ABI"
    Write-Host "  6. troubleshoot       - Common problems"
    Write-Host "  7. after_build        - Next steps after building"
    Write-Host "  8. file_locations     - Where things are"
    Write-Host "  9. timing             - Build time estimates"
    Write-Host "  10. help              - Getting help"
    Write-Host "  q. quit"
    Write-Host ""
}

if ($Section -eq 'all' -or $ShowAll) {
    foreach ($key in @('error', 'windows', 'linux', 'macos', 'architectures', 'troubleshoot', 'after_build', 'file_locations', 'timing', 'help')) {
        Show-Section $key
    }
} else {
    Show-Section $Section
}

# Interactive menu if no parameters
if (-not $ShowAll -and $Section -eq 'all') {
    Write-Host "`n" + ("=" * 80) -ForegroundColor Green
    Write-Host "SimpleX Chat - Android Build Quick Reference" -ForegroundColor Green
    Write-Host ("=" * 80) -ForegroundColor Green

    do {
        Show-Menu
        $choice = Read-Host "Select section [1-10, q=quit]"

        $choices = @{
            '1' = 'error'
            '2' = 'windows'
            '3' = 'linux'
            '4' = 'macos'
            '5' = 'architectures'
            '6' = 'troubleshoot'
            '7' = 'after_build'
            '8' = 'file_locations'
            '9' = 'timing'
            '10' = 'help'
        }

        if ($choices.ContainsKey($choice)) {
            Show-Section $choices[$choice]
        } elseif ($choice.ToLower() -eq 'q') {
            break
        } else {
            Write-Host "Invalid selection" -ForegroundColor Red
        }
    } while ($true)
}

