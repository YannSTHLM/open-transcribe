# Open Transcribe - Stop both servers
# Usage: powershell -ExecutionPolicy Bypass -File stop.ps1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$PidDir = Join-Path $AppDir ".pids"

Write-Host "Stopping Open Transcribe..."

# -------------------------------------------------------
# Stop backend
# -------------------------------------------------------
if (Test-Path "$PidDir\backend.pid") {
    $pid = Get-Content "$PidDir\backend.pid" -ErrorAction SilentlyContinue
    if ($pid -and (Get-Process -Id $pid -ErrorAction SilentlyContinue)) {
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        # Also kill any process on port 8000
        Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | 
            Select-Object -ExpandProperty OwningProcess | 
            ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
        Write-Host "Backend stopped (PID $pid)"
    } else {
        Write-Host "Backend was not running"
    }
    Remove-Item "$PidDir\backend.pid" -Force -ErrorAction SilentlyContinue
} else {
    # Fallback: kill anything on the port
    $portProcs = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | 
        Select-Object -ExpandProperty OwningProcess -Unique
    if ($portProcs) {
        $portProcs | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
        Write-Host "Backend stopped"
    } else {
        Write-Host "Backend was not running"
    }
}

# -------------------------------------------------------
# Stop frontend
# -------------------------------------------------------
if (Test-Path "$PidDir\frontend.pid") {
    $pid = Get-Content "$PidDir\frontend.pid" -ErrorAction SilentlyContinue
    if ($pid -and (Get-Process -Id $pid -ErrorAction SilentlyContinue)) {
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        # Also kill any process on port 5173
        Get-NetTCPConnection -LocalPort 5173 -ErrorAction SilentlyContinue | 
            Select-Object -ExpandProperty OwningProcess | 
            ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
        Write-Host "Frontend stopped (PID $pid)"
    } else {
        Write-Host "Frontend was not running"
    }
    Remove-Item "$PidDir\frontend.pid" -Force -ErrorAction SilentlyContinue
} else {
    $portProcs = Get-NetTCPConnection -LocalPort 5173 -ErrorAction SilentlyContinue | 
        Select-Object -ExpandProperty OwningProcess -Unique
    if ($portProcs) {
        $portProcs | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
        Write-Host "Frontend stopped"
    } else {
        Write-Host "Frontend was not running"
    }
}

Write-Host ""
Write-Host "Open Transcribe stopped."