# Open Transcribe - Start both servers
# Usage: powershell -ExecutionPolicy Bypass -File start.ps1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$PidDir = Join-Path $AppDir ".pids"

if (-not (Test-Path $PidDir)) {
    New-Item -ItemType Directory -Path $PidDir | Out-Null
}

# -------------------------------------------------------
# Check if already running
# -------------------------------------------------------
$backendRunning = $false
$frontendRunning = $false

if (Test-Path "$PidDir\backend.pid") {
    $pid = Get-Content "$PidDir\backend.pid" -ErrorAction SilentlyContinue
    if ($pid -and (Get-Process -Id $pid -ErrorAction SilentlyContinue)) {
        $backendRunning = $true
        Write-Host "Backend server is already running (PID $pid)"
    }
}

if (Test-Path "$PidDir\frontend.pid") {
    $pid = Get-Content "$PidDir\frontend.pid" -ErrorAction SilentlyContinue
    if ($pid -and (Get-Process -Id $pid -ErrorAction SilentlyContinue)) {
        $frontendRunning = $true
        Write-Host "Frontend server is already running (PID $pid)"
    }
}

# -------------------------------------------------------
# Start backend
# -------------------------------------------------------
if (-not $backendRunning) {
    Write-Host "Starting backend server..."
    Set-Location "$AppDir\backend"
    $backendProc = Start-Process -FilePath "powershell" `
        -ArgumentList "-NoWindow", "-ExecutionPolicy", "Bypass", "-Command", "& { cd '$AppDir\backend'; & '.\venv\Scripts\Activate.ps1'; python -m app.main }" `
        -PassThru `
        -WindowStyle Hidden
    $backendProc.Id | Out-File "$PidDir\backend.pid"
    Write-Host "Backend started (PID $($backendProc.Id)) on http://localhost:8000"
}

# -------------------------------------------------------
# Start frontend
# -------------------------------------------------------
if (-not $frontendRunning) {
    Write-Host "Starting frontend server..."
    $frontendProc = Start-Process -FilePath "powershell" `
        -ArgumentList "-NoWindow", "-ExecutionPolicy", "Bypass", "-Command", "& { cd '$AppDir\frontend'; npm run dev }" `
        -PassThru `
        -WindowStyle Hidden
    $frontendProc.Id | Out-File "$PidDir\frontend.pid"
    Write-Host "Frontend started (PID $($frontendProc.Id)) on http://localhost:5173"
}

# -------------------------------------------------------
# Wait for servers to be ready
# -------------------------------------------------------
Write-Host ""
Write-Host "Waiting for servers to be ready..."

$maxWait = 30
$waited = 0
while ($waited -lt $maxWait) {
    try {
        $null = Invoke-WebRequest -Uri "http://localhost:8000/api/v1/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        Write-Host "Backend is ready!" -ForegroundColor Green
        break
    } catch {
        Start-Sleep -Seconds 1
        $waited++
    }
}

$waited = 0
while ($waited -lt $maxWait) {
    try {
        $null = Invoke-WebRequest -Uri "http://localhost:5173" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        Write-Host "Frontend is ready!" -ForegroundColor Green
        break
    } catch {
        Start-Sleep -Seconds 1
        $waited++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   Open Transcribe is running! 🎙️" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Frontend: http://localhost:5173"
Write-Host "  Backend:  http://localhost:8000"
Write-Host "  API Docs: http://localhost:8000/docs"
Write-Host ""

# Open browser
Start-Process "http://localhost:5173"