# CMake Build Configuration - Technical Deep Dive

## Understanding the Error

```
ninja: error: 'D:/works/git/simplex-chat/apps/multiplatform/common/src/commonMain/cpp/android/libs/x86_64/libsimplex.so', 
needed by 'D:/works/git/simplex-chat/apps/multiplatform/android/build/intermediates/cxx/Debug/j5jh3v4l/obj/x86_64/libapp-lib.so', 
missing and no known rule to make it
```

### Breaking Down the Error

1. **Missing File**: `libs/x86_64/libsimplex.so`
   - Ninja (the low-level build tool) can't find this file
   
2. **Dependent Target**: `libapp-lib.so`
   - This is the C library that's being built
   - It depends on `libsimplex.so` being available
   
3. **No Known Rule**: Ninja has no instructions on how to create the missing file
   - Gradle/CMake can't automatically build native Haskell code
   - The `.so` files must be pre-built and placed in the correct directory

## CMake Configuration Files

### Primary Configuration
**File**: `apps/multiplatform/common/src/commonMain/cpp/android/CMakeLists.txt`

```cmake
# Lines 48-50: Define simplex library as pre-built (IMPORTED)
add_library( simplex SHARED IMPORTED )
set_target_properties( simplex PROPERTIES IMPORTED_LOCATION
    ${CMAKE_SOURCE_DIR}/libs/${ANDROID_ABI}/libsimplex.so)

# Lines 52-54: Define support library as pre-built (IMPORTED)
add_library( support SHARED IMPORTED )
set_target_properties( support PROPERTIES IMPORTED_LOCATION
    ${CMAKE_SOURCE_DIR}/libs/${ANDROID_ABI}/libsupport.so)
```

**Key Points**:
- `IMPORTED` keyword tells CMake these are pre-built libraries
- `IMPORTED_LOCATION` specifies the exact path to the `.so` file
- `${ANDROID_ABI}` is substituted by Gradle (e.g., `arm64-v8a`, `x86_64`)
- `${CMAKE_SOURCE_DIR}` is the directory containing `CMakeLists.txt`

### Gradle Integration
**File**: `apps/multiplatform/android/build.gradle.kts` (lines 61-65)

```kotlin
externalNativeBuild {
    cmake {
        path(File("../common/src/commonMain/cpp/android/CMakeLists.txt"))
    }
}
```

Gradle's workflow:
1. Reads CMake configuration
2. Sets `${ANDROID_ABI}` variable based on architecture being built
3. Runs CMake with the `ANDROID_ABI` variable
4. CMake tries to find the libraries specified in `IMPORTED_LOCATION`
5. If files don't exist, CMake/Ninja fails

## Path Resolution

### Relative Path Expansion

When Gradle runs CMake:

```
CMakeLists.txt location:
  D:\works\git\simplex-chat\apps\multiplatform\common\src\commonMain\cpp\android\CMakeLists.txt
  └─ ${CMAKE_SOURCE_DIR} = D:\...\cpp\android

Library path in CMakeLists.txt:
  ${CMAKE_SOURCE_DIR}/libs/${ANDROID_ABI}/libsimplex.so
  
Expanded for x86_64:
  D:\...\cpp\android\libs\x86_64\libsimplex.so
  
But the libraries are in:
  D:\...\common\src\commonMain\cpp\android\libs\x86_64\libsimplex.so
                                          ^^^ Same directory! ✓
```

### Directory Structure Expected

```
apps/multiplatform/common/src/commonMain/cpp/android/
├── CMakeLists.txt               ← CMAKE_SOURCE_DIR points here
├── simplex-api.c                ← C wrapper code
└── libs/
    ├── arm64-v8a/               ← ANDROID_ABI = arm64-v8a
    │   ├── libsimplex.so        ← MUST exist for ARM64 builds
    │   ├── libsupport.so
    │   ├── libssl.so.1.1
    │   └── libcrypto.so.1.1
    ├── armeabi-v7a/             ← ANDROID_ABI = armeabi-v7a
    │   ├── libsimplex.so        ← MUST exist for ARMv7 builds
    │   ├── libsupport.so
    │   └── ...
    └── x86_64/                  ← ANDROID_ABI = x86_64
        ├── libsimplex.so        ← MUST exist for x86_64 builds
        ├── libsupport.so
        └── ...
```

## Building the Imported Libraries

### The C Wrapper Layer

**File**: `simplex-api.c`

This C code wraps Haskell functions for Android/Kotlin interop:

```c
// Declares functions from the Haskell library
extern char* chat_send_cmd(const char* store_path, char* cmd);
extern int chat_recv_msg(const char* store_path, char* resp);
// ... more Haskell function declarations

// Java/Kotlin calls these C functions
JNIEXPORT jstring JNICALL
Java_chat_simplex_app_ChatAPI_sendCommand(
    JNIEnv *env,
    jclass clazz,
    jstring store_path,
    jstring cmd) {
    // Calls the Haskell function
    char* result = chat_send_cmd(...);
    return (*env)->NewStringUTF(env, result);
}
```

### Build Steps Explained

1. **Build Haskell Library** (Nix/External)
   ```
   Haskell Source Code
   src/Simplex/Chat/*.hs
         ↓
   [GHC Compiler] (via Nix)
         ↓
   libsimplex.so (shared object)
   ```

2. **Place in libs Directory**
   ```
   libsimplex.so
         ↓
   apps/multiplatform/common/src/commonMain/cpp/android/libs/{ABI}/
   ```

3. **Link with C Wrapper** (CMake/Gradle)
   ```
   C Wrapper Code (simplex-api.c)
         ↓
   [CMake + NDK C Compiler]
         ↓
   libapp-lib.so
   ```

4. **Package in APK**
   ```
   libapp-lib.so
   libsimplex.so
   libsupport.so
         ↓
   [APK Packager]
         ↓
   chat.simplex.app.apk
   ```

## Android ABI Matrix

The build supports multiple architectures:

| ABI | Architecture | Devices | libsimplex.so Name | Notes |
|-----|-------------|---------|-------------------|-------|
| `arm64-v8a` | 64-bit ARM | Modern Android | Built for aarch64-unknown-linux-android | Primary target |
| `armeabi-v7a` | 32-bit ARM | Older devices | Built for armv7a-unknown-linux-androideabi | Compatibility |
| `x86_64` | Intel x86 64-bit | Emulators | Built for x86_64-unknown-linux-android | Testing |
| `x86` | Intel x86 32-bit | Old emulators | Built for i686-unknown-linux-android | Legacy |

### How Gradle Selects Architecture

From `build.gradle.kts` (lines 114-127):

```kotlin
if (isRelease) {
    include("arm64-v8a", "armeabi-v7a")  // Production ABIs
} else {
    include("arm64-v8a", "armeabi-v7a", "x86_64", "x86")  // Dev ABIs
}
```

For **each** ABI being built:
1. Gradle extracts matching libraries from `libs/{ABI}/`
2. Passes `ANDROID_ABI={ABI}` to CMake
3. CMake tries to load `libs/{ABI}/libsimplex.so`

## Dependency Graph

### Runtime Dependencies

```
libapp-lib.so (Java entry point)
├── libsimplex.so (Haskell runtime + chat logic)
│   ├── libffi.so (Foreign function interface)
│   ├── libssl.so (OpenSSL)
│   ├── libcrypto.so (OpenSSL crypto)
│   ├── libgmp.so (Big integer library)
│   └── [Haskell RTS] (Haskell runtime system)
└── libsupport.so (Android JNI support)
    └── [Android C library]
```

### Build Dependency Graph

```
libsimplex.so
├── Haskell Source Code (src/Simplex/Chat/)
├── Cabal Dependencies (simplex-chat.cabal)
├── GHC (Haskell Compiler)
├── Android NDK (Cross-compiler)
└── OpenSSL, GMP, etc. (System libraries)

libsupport.so
├── android-support repo
└── Android NDK
```

## Nix Build Outputs

### How Nix Packages Libraries

From `flake.nix` (lines 436-441):

```nix
(cd $out/_pkg; ${pkgs.zip}/bin/zip -r -9 $out/pkg-armv7a-android-libsimplex.zip *)
```

Nix outputs:
```
/nix/store/.../pkg-armv7a-android-libsimplex.zip
├── libsimplex.so
├── libssl.so.1.1
├── libcrypto.so.1.1
└── libgmp.so.10
```

### Extraction Process

The build script extracts this:

```bash
# From scripts/android/build-android.sh (lines 128-132)
mkdir -p "$libs_folder/$android_arch"
nix build "$android_simplex_lib"
unzip -o "$android_simplex_lib_output" -d "$libs_folder/$android_arch"
```

Results in:
```
libs/arm64-v8a/
├── libsimplex.so
├── libssl.so.1.1
├── libcrypto.so.1.1
└── libgmp.so.10
```

## Troubleshooting Checklist

### 1. Verify Files Exist

```bash
# Check directory structure
ls -la apps/multiplatform/common/src/commonMain/cpp/android/libs/x86_64/

# Expected output:
# -rw-r--r-- libsimplex.so
# -rw-r--r-- libsupport.so
# ... other dependencies
```

### 2. Verify File Types

```bash
# On Linux/macOS
file apps/multiplatform/common/src/commonMain/cpp/android/libs/x86_64/libsimplex.so

# Expected output:
# ELF 64-bit LSB shared object, ARM aarch64, dynamically linked
```

### 3. Check Permissions

```bash
# Make sure files are readable
chmod +r apps/multiplatform/common/src/commonMain/cpp/android/libs/*/lib*.so
```

### 4. Verify File Size

```bash
# libsimplex.so should be 5-8 MB
# libsupport.so should be ~500 KB
ls -lh apps/multiplatform/common/src/commonMain/cpp/android/libs/*/
```

### 5. Clean Gradle Cache

```bash
cd apps/multiplatform
./gradlew clean
./gradlew :android:assembleDebug
```

### 6. Clear CMake Cache

```bash
rm -rf android/build/intermediates/cxx
rm -rf android/.gradle
```

## Integration with Gradle Build Phases

### Phase 1: Configure
```
Gradle reads build.gradle.kts
└─ Detects externalNativeBuild -> CMake
```

### Phase 2: Generate CMake
```
Gradle invokes CMake
├─ Sets ANDROID_ABI = arm64-v8a (or other ABI)
├─ Passes path to CMakeLists.txt
└─ CMake expands variables
```

### Phase 3: Parse CMakeLists.txt
```
CMake reads CMakeLists.txt
├─ Finds: add_library(simplex SHARED IMPORTED)
├─ Expands: IMPORTED_LOCATION = libs/arm64-v8a/libsimplex.so
└─ Checks: Does libs/arm64-v8a/libsimplex.so exist?
   ├─ YES ✓ → Continue to next phase
   └─ NO ✗ → "missing and no known rule to make it" ERROR
```

### Phase 4: Generate Ninja Build
```
CMake generates build.ninja
├─ Defines: link libapp-lib.so
├─ Requires: libsimplex.so, libsupport.so
└─ If required files missing → Ninja error
```

## Performance Considerations

### Build Cache

Nix maintains a binary cache, so second builds are much faster:

```
First build:  nix build '.#aarch64-android:lib:simplex-chat'
└─ Compiles from source: 25-35 minutes

Second build: nix build '.#aarch64-android:lib:simplex-chat'
└─ Uses cache: 2-5 seconds
```

### Parallel Compilation

CMake can build multiple ABIs in parallel:

```gradle
// In build.gradle.kts
gradle -p $folder clean \
  :android:assembleDebug \
  -PabiFilter=arm64-v8a \
  -Dorg.gradle.parallel=true \
  -Dorg.gradle.workers.max=4
```

## Debugging CMake

If you need to debug CMake itself:

```bash
# Enable verbose output
cd apps/multiplatform
./gradlew :android:assembleDebug --info | grep -A 20 "CMake"

# Or check the CMake log directly
cat android/build/intermediates/cxx/debug/*/build.log
```

## References

- **CMake Documentation**: https://cmake.org/cmake/help/latest/
- **Android NDK CMake**: https://developer.android.com/studio/projects/add-native-code
- **Gradle ExternalNativeBuild**: https://docs.gradle.org/current/userguide/building_cpp_projects.html

