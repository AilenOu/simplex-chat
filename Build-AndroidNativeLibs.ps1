#!/usr/bin/env powershell

<#
.SYNOPSIS
Windows helper script to build SimpleX Chat native Android libraries using WSL2 or Docker

.DESCRIPTION
This script provides an easy way to build native Haskell libraries for Android
on a Windows system without manually installing Nix. It supports both WSL2 and Docker approaches.

.PARAMETER Method
The build method: 'wsl2', 'docker', or 'check'

.PARAMETER ABI
The Android ABI to build: 'arm64-v8a', 'armeabi-v7a', 'x86_64', 'all'

.PARAMETER ProjectPath
Path to the simplex-chat project root

.EXAMPLE
.\Build-AndroidNativeLibs.ps1 -Method wsl2 -ABI arm64-v8a
Build for arm64-v8a using WSL2

.EXAMPLE
.\Build-AndroidNativeLibs.ps1 -Method docker -ABI all
Build for all ABIs using Docker

.EXAMPLE
.\Build-AndroidNativeLibs.ps1 -Method check
Check system prerequisites
#>

param(
    [ValidateSet('wsl2', 'docker', 'check')]
    [string]$Method = 'check',

    [ValidateSet('arm64-v8a', 'armeabi-v7a', 'x86_64', 'all')]
    [string]$ABI = 'arm64-v8a',

    [string]$ProjectPath = (Get-Location).Path
)

# Color output helper
function Write-Header {
    param([string]$Message)
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

# Check if project path is valid
function Test-ProjectPath {
    if (-not (Test-Path "$ProjectPath\flake.nix")) {
        Write-Error "Project not found at: $ProjectPath"
        Write-Info "Please specify correct path with -ProjectPath parameter"
        return $false
    }
    Write-Success "Project found: $ProjectPath"
    return $true
}

# Check WSL2 installation
function Test-WSL2 {
    Write-Header "Checking WSL2..."

    try {
        $wslVersion = wsl --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "WSL2 is installed"
            Write-Info "$wslVersion"
            return $true
        }
    }
    catch {
        Write-Error "WSL2 not found"
    }

    Write-Warning "To install WSL2:"
    Write-Info "  1. Open PowerShell as Administrator"
    Write-Info "  2. Run: wsl --install"
    Write-Info "  3. Restart your computer"
    Write-Info "  4. Install Nix in WSL2: https://nixos.org/download.html#nix-install-windows"

    return $false
}

# Check Docker installation
function Test-Docker {
    Write-Header "Checking Docker..."

    try {
        $dockerVersion = docker --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker is installed"
            Write-Info "$dockerVersion"
            return $true
        }
    }
    catch {
        Write-Error "Docker not found"
    }

    Write-Warning "To install Docker:"
    Write-Info "  1. Download Docker Desktop: https://www.docker.com/products/docker-desktop"
    Write-Info "  2. Install and restart"
    Write-Info "  3. Ensure Docker daemon is running"

    return $false
}

# Build using WSL2
function Build-WithWSL2 {
    param([string]$ABI)

    Write-Header "Building with WSL2 for $ABI"

    # Convert Windows path to WSL path
    $wslPath = $ProjectPath -replace '\\', '/' -replace '^([A-Z]):', '/mnt/$1'

    Write-Info "Project path in WSL: $wslPath"
    Write-Info "ABI: $ABI"

    # Build command based on ABI
    $buildCmd = if ($ABI -eq 'all') {
        "bash $wslPath/scripts/android/build-android.sh"
    } else {
        # Map ABI to arch for Nix
        $arch = switch ($ABI) {
            'arm64-v8a' { 'aarch64' }
            'armeabi-v7a' { 'armv7a' }
            'x86_64' { 'x86_64' }
            default { throw "Unknown ABI: $ABI" }
        }
        "bash $wslPath/scripts/android/build-android.sh -s -g $arch"
    }

    Write-Info "Running: $buildCmd"
    Write-Warning "This will take 20-60 minutes depending on your system..."

    wsl -- $buildCmd

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Build completed successfully!"
        Write-Info "Libraries are in: $ProjectPath\apps\multiplatform\common\src\commonMain\cpp\android\libs\$ABI"
        return $true
    } else {
        Write-Error "Build failed with exit code: $LASTEXITCODE"
        return $false
    }
}

# Build using Docker
function Build-WithDocker {
    param([string]$ABI)

    Write-Header "Building with Docker for $ABI"

    Write-Info "ABI: $ABI"
    Write-Warning "This will take 20-60 minutes depending on your system..."

    # Build command based on ABI
    $buildCmd = if ($ABI -eq 'all') {
        '/workspace/scripts/android/build-android.sh'
    } else {
        # Map ABI to arch for Nix
        $arch = switch ($ABI) {
            'arm64-v8a' { 'aarch64' }
            'armeabi-v7a' { 'armv7a' }
            'x86_64' { 'x86_64' }
            default { throw "Unknown ABI: $ABI" }
        }
        "/workspace/scripts/android/build-android.sh -s -g $arch"
    }

    Write-Info "Building Docker image..."
    docker build -f "$ProjectPath\Dockerfile" -t simplex-chat-android .

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build Docker image"
        return $false
    }

    Write-Info "Running build in Docker container..."
    docker run `
        -v "$ProjectPath`:/workspace" `
        -e ARCHES=$($ABI -eq 'all' ? 'aarch64 armv7a' : ($ABI -eq 'arm64-v8a' ? 'aarch64' : ($ABI -eq 'armeabi-v7a' ? 'armv7a' : 'x86_64'))) `
        simplex-chat-android `
        bash -c $buildCmd

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Build completed successfully!"
        Write-Info "Libraries are in: $ProjectPath\apps\multiplatform\common\src\commonMain\cpp\android\libs\$ABI"
        return $true
    } else {
        Write-Error "Build failed with exit code: $LASTEXITCODE"
        return $false
    }
}

# Check prerequisites
function Invoke-Check {
    Write-Header "Checking Prerequisites"

    $requirements = @{
        'Project Path' = (Test-ProjectPath)
        'Java' = ($(java -version 2>&1) -match 'version' ? $true : $false)
        'Android SDK' = ($(if (Test-Path $env:ANDROID_HOME) { $true } else { $false }))
        'Gradle' = ($(if (Get-Command gradle -ErrorAction SilentlyContinue) { $true } else { $false }))
    }

    Write-Host "`nBuild Methods:" -ForegroundColor Cyan
    $wsl2Available = Test-WSL2
    $dockerAvailable = Test-Docker

    Write-Host "`nOther Requirements:" -ForegroundColor Cyan
    foreach ($req in $requirements.GetEnumerator()) {
        if ($req.Value) {
            Write-Success "$($req.Key) installed"
        } else {
            Write-Warning "$($req.Key) not found"
        }
    }

    Write-Host "`nRecommended Next Steps:" -ForegroundColor Cyan
    if ($wsl2Available) {
        Write-Info "Run: .\Build-AndroidNativeLibs.ps1 -Method wsl2 -ABI arm64-v8a"
    } elseif ($dockerAvailable) {
        Write-Info "Run: .\Build-AndroidNativeLibs.ps1 -Method docker -ABI arm64-v8a"
    } else {
        Write-Warning "Install either WSL2 or Docker to build native libraries"
    }
}

# Main execution
switch ($Method) {
    'check' {
        Invoke-Check
    }
    'wsl2' {
        if (-not (Test-ProjectPath)) { exit 1 }
        if (-not (Test-WSL2)) { exit 1 }
        if (-not (Build-WithWSL2 $ABI)) { exit 1 }
    }
    'docker' {
        if (-not (Test-ProjectPath)) { exit 1 }
        if (-not (Test-Docker)) { exit 1 }
        if (-not (Build-WithDocker $ABI)) { exit 1 }
    }
}

Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Success "Done!"
Write-Info "For more information, see ANDROID_NATIVE_BUILD_GUIDE.md"

