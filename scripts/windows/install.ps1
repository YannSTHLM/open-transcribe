# Open Transcribe - Windows First-Run Installer
# Run as Administrator for best results
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Open Transcribe - First Run Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# -------------------------------------------------------
# Helper functions
# -------------------------------------------------------
function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-PythonVersion {
    try {
        $version = python3 --version 2>$null
        if ($LASTEXITCODE -ne 0) { return $null }
        return $version -replace 'Python ', ''
    } catch {
        return $null
    }
}

# -------------------------------------------------------
# 1. Check for Python 3.10+
# -------------------------------------------------------
$pythonOk = $false
if (Test-Command "python3") {
    $pyVer = Get-PythonVersion
    if ($pyVer -and [version]$pyVer -ge [version]"3.10") {
        $pythonOk = $true
        Write-Host "✓ Python $pyVer found" -ForegroundColor Green
    }
} elseif (Test-Command "python") {
    $pyVer = (python --version 2>$null) -replace 'Python ', ''
    if ($pyVer -and [version]$pyVer -ge [version]"3.10") {
        $pythonOk = $true
        Write-Host "✓ Python $pyVer found" -ForegroundColor Green
    }
}

if (-not $pythonOk) {
    Write-Host "Python 3.10+ not found. Installing via winget..." -ForegroundColor Yellow
    try {
        winget install Python.Python.3.12 --accept-package-agreements --accept-source-agreements
        Write-Host "✓ Python installed" -ForegroundColor Green
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    } catch {
        Write-Host "Could not install Python automatically." -ForegroundColor Red
        Write-Host "Please install Python 3.12+ from https://www.python.org/downloads/" -ForegroundColor Red
        Write-Host "Make sure to check 'Add Python to PATH' during installation." -ForegroundColor Red
        Read-Host "Press Enter after installing Python to continue"
    }
}

# -------------------------------------------------------
# 2. Check for Node.js 18+
# -------------------------------------------------------
$nodeOk = $false
if (Test-Command "node") {
    $nodeVer = (node -v) -replace 'v', '' -replace '\..*', ''
    if ([int]$nodeVer -ge 18) {
        $nodeOk = $true
        Write-Host "✓ Node.js $(node -v) found" -ForegroundColor Green
    }
}

if (-not $nodeOk) {
    Write-Host "Node.js 18+ not found. Installing via winget..." -ForegroundColor Yellow
    try {
        winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
        Write-Host "✓ Node.js installed" -ForegroundColor Green
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    } catch {
        Write-Host "Could not install Node.js automatically." -ForegroundColor Red
        Write-Host "Please install Node.js 20+ from https://nodejs.org/" -ForegroundColor Red
        Read-Host "Press Enter after installing Node.js to continue"
    }
}

# -------------------------------------------------------
# 3. Check for FFmpeg
# -------------------------------------------------------
if (-not (Test-Command "ffmpeg")) {
    Write-Host "FFmpeg not found. Installing via winget..." -ForegroundColor Yellow
    try {
        winget install Gyan.FFmpeg --accept-package-agreements --accept-source-agreements
        Write-Host "✓ FFmpeg installed" -ForegroundColor Green
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    } catch {
        Write-Host "Could not install FFmpeg automatically." -ForegroundColor Red
        Write-Host "Please install FFmpeg from https://ffmpeg.org/download.html" -ForegroundColor Red
        Read-Host "Press Enter after installing FFmpeg to continue"
    }
} else {
    Write-Host "✓ FFmpeg found" -ForegroundColor Green
}

Write-Host ""
Write-Host "Setting up backend..." -ForegroundColor Cyan

# -------------------------------------------------------
# 4. Create virtual environment
# -------------------------------------------------------
Set-Location "$AppDir\backend"

if (-not (Test-Path "venv")) {
    Write-Host "Creating Python virtual environment..." -ForegroundColor Blue
    python -m venv venv
    Write-Host "✓ Virtual environment created" -ForegroundColor Green
} else {
    Write-Host "✓ Virtual environment exists" -ForegroundColor Green
}

# -------------------------------------------------------
# 5. Install Python dependencies
# -------------------------------------------------------
Write-Host "Installing Python dependencies (this may take a minute)..." -ForegroundColor Blue
& ".\venv\Scripts\Activate.ps1"
pip install --upgrade pip -q
pip install -r requirements.txt -q
Write-Host "✓ Python dependencies installed" -ForegroundColor Green

# -------------------------------------------------------
# 6. Copy .env if needed
# -------------------------------------------------------
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "✓ Created .env from .env.example" -ForegroundColor Green
}

# -------------------------------------------------------
# 7. Create data directories
# -------------------------------------------------------
New-Item -ItemType Directory -Force -Path "data\uploads" | Out-Null
New-Item -ItemType Directory -Force -Path "data\transcriptions" | Out-Null

Write-Host ""
Write-Host "Setting up frontend..." -ForegroundColor Cyan

# -------------------------------------------------------
# 8. Install Node.js dependencies
# -------------------------------------------------------
Set-Location "$AppDir\frontend"

if (-not (Test-Path "node_modules")) {
    Write-Host "Installing Node.js dependencies (this may take a minute)..." -ForegroundColor Blue
    npm install
    Write-Host "✓ Node.js dependencies installed" -ForegroundColor Green
} else {
    Write-Host "✓ Node.js dependencies exist" -ForegroundColor Green
}

# -------------------------------------------------------
# 9. Build frontend for production
# -------------------------------------------------------
if (-not (Test-Path "dist")) {
    Write-Host "Building frontend for production..." -ForegroundColor Blue
    npm run build
    Write-Host "✓ Frontend built" -ForegroundColor Green
} else {
    Write-Host "✓ Frontend build exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "       Setup Complete! 🎉" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "You can now launch Open Transcribe."
Write-Host ""