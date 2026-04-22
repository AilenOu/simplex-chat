# 📖 SimpleX Chat Android Build - Documentation Index

## 🎯 Your Error

```
ninja: error: 'D:/works/git/simplex-chat/apps/multiplatform/common/src/commonMain/cpp/android/libs/x86_64/libsimplex.so', needed by '...libapp-lib.so', missing and no known rule to make it
```

**Translation**: The Android build needs a native Haskell library that doesn't exist yet.

## ✅ Solution: 3 Steps

1. **Understand** what's missing (2 minutes)
2. **Build** the native libraries (30-60 minutes)
3. **Build** the Android APK (5-15 minutes)

## 🚀 Quick Start (Pick Your OS)

### Windows
```powershell
# Option A: Docker (easiest)
.\Build-AndroidNativeLibs.ps1 -Method docker -ABI arm64-v8a

# Option B: WSL2
.\Build-AndroidNativeLibs.ps1 -Method wsl2 -ABI arm64-v8a

# Check what you have
.\Build-AndroidNativeLibs.ps1 -Method check
```

### Linux
```bash
./scripts/android/build-android.sh arm64-v8a
```

### macOS
```bash
./scripts/android/build-android.sh arm64-v8a
```

## 📚 Documentation Guide

### START HERE 👇

#### 1. **ANDROID_QUICK_FIX.md** ⭐⭐⭐
   - **Read time**: 5 minutes
   - **Best for**: First-time builders who want fast results
   - **Contains**: One-command solutions for each OS
   - **Next**: Run the build command, then come back to verify

#### 2. **ANDROID_BUILD_VISUAL_GUIDE.md** 📊
   - **Read time**: 10 minutes
   - **Best for**: Visual learners wanting to understand the process
   - **Contains**: Diagrams, flowcharts, time estimates
   - **Next**: Helps understand what's happening during builds

#### 3. **ANDROID_QUICK_REFERENCE.ps1** (Windows) 🔍
   - **Type**: Interactive PowerShell script
   - **Best for**: Quick command lookup
   - **Run**: `.\ANDROID_QUICK_REFERENCE.ps1`
   - **Contains**: Commands, timing, architecture guide, troubleshooting

---

### DEEP UNDERSTANDING 📖

#### 4. **ANDROID_BUILD_ERROR_RESOLUTION.md**
   - **Read time**: 15 minutes
   - **Best for**: Complete overview of the issue and solution
   - **Contains**: Root cause, all methods, architecture guide, next steps
   - **Use as**: Master reference document

#### 5. **ANDROID_NATIVE_BUILD_GUIDE.md**
   - **Read time**: 20-30 minutes
   - **Best for**: Comprehensive step-by-step instructions
   - **Contains**: All build methods, options, Windows WSL2 guide, CI/CD info
   - **Use as**: Complete reference for all scenarios

#### 6. **CMAKE_BUILD_GUIDE.md**
   - **Read time**: 30-40 minutes
   - **Best for**: Developers wanting technical details
   - **Contains**: CMake internals, Ninja explanation, dependency graphs, debugging
   - **Use as**: Technical troubleshooting reference

---

### TOOLS & AUTOMATION 🛠️

#### 7. **Build-AndroidNativeLibs.ps1** (Windows)
   - **Type**: PowerShell automation script
   - **Best for**: Automated builds on Windows
   - **Methods**: Docker, WSL2, prerequisite checking
   - **Usage**:
     ```powershell
     .\Build-AndroidNativeLibs.ps1 -Method docker -ABI arm64-v8a
     ```

#### 8. **ANDROID_QUICK_REFERENCE.ps1** (Windows)
   - **Type**: Interactive PowerShell script
   - **Best for**: Quick command lookup and information
   - **Usage**:
     ```powershell
     .\ANDROID_QUICK_REFERENCE.ps1 -ShowAll
     .\ANDROID_QUICK_REFERENCE.ps1 -Section windows
     ```

---

### OVERVIEW 📋

#### 9. **README_ANDROID_BUILD_RESOURCES.md**
   - **This file**: Complete resource index
   - **Best for**: Understanding what documentation exists
   - **Contains**: File summaries, learning paths, quick links

---

## 📚 Recommended Reading Order

### Path 1: Just Build It (⏱️ 60-90 minutes)
1. Skim: ANDROID_QUICK_FIX.md (2 min)
2. Run: Build-AndroidNativeLibs.ps1 (30-60 min)
3. Check: Verify libraries exist (2 min)
4. Build: ./gradlew assembleDebug (5-15 min)
5. Done! ✅

### Path 2: Understand Then Build (⏱️ 70-100 minutes)
1. Read: ANDROID_BUILD_VISUAL_GUIDE.md (10 min)
2. Skim: ANDROID_QUICK_FIX.md (5 min)
3. Run: Build script (30-60 min)
4. Read: ANDROID_NATIVE_BUILD_GUIDE.md (20 min)
5. Build: ./gradlew assembleDebug (5-15 min)
6. Done! ✅

### Path 3: Master It (⏱️ 90-150 minutes)
1. Read: ANDROID_BUILD_ERROR_RESOLUTION.md (15 min)
2. Read: ANDROID_BUILD_VISUAL_GUIDE.md (10 min)
3. Read: CMAKE_BUILD_GUIDE.md (30 min)
4. Read: ANDROID_NATIVE_BUILD_GUIDE.md (25 min)
5. Run: Build script with understanding (30-60 min)
6. Build: ./gradlew assembleDebug (5-15 min)
7. Done! ✅

### Path 4: Troubleshoot (Specific Issue)
1. Run: `.\Build-AndroidNativeLibs.ps1 -Method check`
2. See: ANDROID_QUICK_REFERENCE.ps1 -Section troubleshoot
3. Check: CMAKE_BUILD_GUIDE.md → Troubleshooting Checklist
4. Review: ANDROID_NATIVE_BUILD_GUIDE.md → Common Issues

---

## 🎯 Quick Decision Tree

```
START
  │
  ├─ Need to build NOW?
  │  └─ YES → ANDROID_QUICK_FIX.md
  │           (Then run Build-AndroidNativeLibs.ps1)
  │
  ├─ Want to understand why?
  │  └─ YES → ANDROID_BUILD_VISUAL_GUIDE.md
  │           (Then read ANDROID_BUILD_ERROR_RESOLUTION.md)
  │
  ├─ Technical troubleshooting needed?
  │  └─ YES → CMAKE_BUILD_GUIDE.md
  │           (Then use troubleshooting checklist)
  │
  ├─ Windows user needing quick reference?
  │  └─ YES → ANDROID_QUICK_REFERENCE.ps1
  │           (Run: .\ANDROID_QUICK_REFERENCE.ps1)
  │
  └─ Need complete reference for future?
     └─ YES → ANDROID_NATIVE_BUILD_GUIDE.md
              (Save and use as needed)
```

---

## 📊 File Summary Table

| File | Type | Length | Read Time | Purpose |
|------|------|--------|-----------|---------|
| ANDROID_QUICK_FIX.md | Doc | 500 lines | 5 min | Quick solutions |
| ANDROID_NATIVE_BUILD_GUIDE.md | Doc | 800+ lines | 20-30 min | Complete guide |
| ANDROID_BUILD_ERROR_RESOLUTION.md | Doc | 600+ lines | 15 min | Full overview |
| CMAKE_BUILD_GUIDE.md | Doc | 1000+ lines | 30-40 min | Technical details |
| ANDROID_BUILD_VISUAL_GUIDE.md | Doc | 400+ lines | 10 min | Visual diagrams |
| Build-AndroidNativeLibs.ps1 | Script | 300 lines | N/A | Automation |
| ANDROID_QUICK_REFERENCE.ps1 | Script | 500 lines | N/A | Interactive lookup |
| README_ANDROID_BUILD_RESOURCES.md | Index | 400+ lines | 10 min | Resource overview |
| ANDROID_QUICK_REFERENCE.sh | Script | - | N/A | (Future) Linux version |

**Total Documentation**: ~5000+ lines, ~50+ pages equivalent

---

## 🔍 Find Answer to Specific Questions

### "How do I build the native libraries?"
→ **ANDROID_QUICK_FIX.md** - One command solutions

### "Why am I getting this error?"
→ **CMAKE_BUILD_GUIDE.md** → Understanding the Error section

### "What's the complete build process?"
→ **ANDROID_NATIVE_BUILD_GUIDE.md**

### "How long does building take?"
→ **ANDROID_QUICK_REFERENCE.ps1** -Section timing
→ Or: **ANDROID_BUILD_VISUAL_GUIDE.md** → Time Breakdown

### "I don't have Nix installed. Can I still build?"
→ **ANDROID_NATIVE_BUILD_GUIDE.md** → Option 3: Docker Build

### "Which architecture should I build?"
→ **ANDROID_QUICK_REFERENCE.ps1** -Section architectures
→ Or: **ANDROID_BUILD_VISUAL_GUIDE.md** → Architecture Selection

### "My build is failing. How do I debug?"
→ **CMAKE_BUILD_GUIDE.md** → Debugging CMake section
→ Or: **ANDROID_NATIVE_BUILD_GUIDE.md** → Troubleshooting section

### "How do I build for production?"
→ **ANDROID_NATIVE_BUILD_GUIDE.md** → Multiple ABIs
→ Or: **ANDROID_QUICK_REFERENCE.ps1** -Section after_build

### "I'm on Windows, what are my options?"
→ **ANDROID_QUICK_FIX.md** → Windows section
→ Or: **Build-AndroidNativeLibs.ps1** (run the script)

### "I need a quick checklist for troubleshooting"
→ **CMAKE_BUILD_GUIDE.md** → Troubleshooting Checklist
→ Or: **ANDROID_NATIVE_BUILD_GUIDE.md** → Troubleshooting

---

## 🎓 Learning Resources

### For Beginners
1. Start with: **ANDROID_BUILD_VISUAL_GUIDE.md** (visual understanding)
2. Then: **ANDROID_QUICK_FIX.md** (execute)
3. Reference: **ANDROID_QUICK_REFERENCE.ps1** (lookups)

### For Intermediate Users
1. Start with: **ANDROID_BUILD_ERROR_RESOLUTION.md** (complete picture)
2. Deep dive: **ANDROID_NATIVE_BUILD_GUIDE.md** (all options)
3. Reference: **CMAKE_BUILD_GUIDE.md** (technical)

### For Advanced Users/Troubleshooting
1. Study: **CMAKE_BUILD_GUIDE.md** (internals)
2. Debug with: Troubleshooting checklists
3. Customize: Build scripts as needed
4. Contribute: Improvements to documentation

---

## 🔗 Quick Links

### Most Important Files
- 🌟 **ANDROID_QUICK_FIX.md** - Start here!
- 🌟 **Build-AndroidNativeLibs.ps1** - Windows helper
- 🌟 **ANDROID_QUICK_REFERENCE.ps1** - Quick lookup

### Comprehensive Guides
- 📖 **ANDROID_NATIVE_BUILD_GUIDE.md** - Complete reference
- 📖 **ANDROID_BUILD_ERROR_RESOLUTION.md** - Master guide
- 📖 **CMAKE_BUILD_GUIDE.md** - Technical details

### Helpful Visualizations
- 📊 **ANDROID_BUILD_VISUAL_GUIDE.md** - Diagrams and flows

### This Index
- 📋 **README_ANDROID_BUILD_RESOURCES.md** - You are here

---

## ✅ Success Checklist

- [ ] Read one of the quick start guides
- [ ] Run the appropriate build command for your OS
- [ ] Wait for native libraries to build (30-60 min)
- [ ] Verify libraries exist: `ls libs/arm64-v8a/libsimplex.so`
- [ ] Build Android APK: `./gradlew assembleDebug`
- [ ] Test on device or emulator
- [ ] Success! 🎉

---

## 🆘 Getting Help

### If you get stuck:

1. **Check Quick Reference**
   ```powershell
   .\ANDROID_QUICK_REFERENCE.ps1 -Section troubleshoot
   ```

2. **Check Troubleshooting Guides**
   - ANDROID_NATIVE_BUILD_GUIDE.md → Troubleshooting
   - CMAKE_BUILD_GUIDE.md → Troubleshooting Checklist

3. **Run Prerequisite Check**
   ```powershell
   .\Build-AndroidNativeLibs.ps1 -Method check
   ```

4. **Review Technical Details**
   - CMAKE_BUILD_GUIDE.md → Debugging CMake section

---

## 📝 Document Maintenance

All documentation files are maintained in the root directory:
```
D:\works\git\simplex-chat\
├── ANDROID_*.md          ← All documentation
├── Build-*.ps1           ← All tools
└── README_ANDROID_*.md   ← This index
```

Last Updated: **2026-04-22**  
Total Files Created: **8**  
Total Documentation: **~5000+ lines**

---

## 🎯 Next Step

**Pick your situation:**

- 🏃 **I just want to build ASAP**
  → Go to: **ANDROID_QUICK_FIX.md**

- 🤔 **I want to understand what's happening**
  → Go to: **ANDROID_BUILD_VISUAL_GUIDE.md**

- 🔍 **I need detailed step-by-step instructions**
  → Go to: **ANDROID_NATIVE_BUILD_GUIDE.md**

- 🛠️ **I'm troubleshooting a problem**
  → Go to: **CMAKE_BUILD_GUIDE.md**

- 🪟 **I'm on Windows and need help**
  → Use: **Build-AndroidNativeLibs.ps1**

---

**You've got this! 💪**

All the documentation you need is here. Pick the right guide for your situation and follow along. The build process is straightforward once you understand what needs to happen.

