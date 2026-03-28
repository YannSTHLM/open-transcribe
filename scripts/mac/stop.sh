#!/bin/bash
# Open Transcribe - Stop both servers

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PID_DIR="$APP_DIR/.pids"

echo "Stopping Open Transcribe..."

# Stop backend
if [ -f "$PID_DIR/backend.pid" ]; then
    BACKEND_PID=$(cat "$PID_DIR/backend.pid")
    if kill -0 "$BACKEND_PID" 2>/dev/null; then
        # Kill the process tree (uvicorn + workers)
        kill -TERM "$BACKEND_PID" 2>/dev/null
        # Also kill any uvicorn child processes on port 8000
        lsof -ti:8000 | xargs kill -TERM 2>/dev/null || true
        echo "Backend stopped (PID $BACKEND_PID)"
    else
        echo "Backend was not running"
    fi
    rm -f "$PID_DIR/backend.pid"
else
    # Fallback: kill anything on the ports
    lsof -ti:8000 | xargs kill -TERM 2>/dev/null && echo "Backend stopped" || echo "Backend was not running"
fi

# Stop frontend
if [ -f "$PID_DIR/frontend.pid" ]; then
    FRONTEND_PID=$(cat "$PID_DIR/frontend.pid")
    if kill -0 "$FRONTEND_PID" 2>/dev/null; then
        kill -TERM "$FRONTEND_PID" 2>/dev/null
        lsof -ti:5173 | xargs kill -TERM 2>/dev/null || true
        echo "Frontend stopped (PID $FRONTEND_PID)"
    else
        echo "Frontend was not running"
    fi
    rm -f "$PID_DIR/frontend.pid"
else
    lsof -ti:5173 | xargs kill -TERM 2>/dev/null && echo "Frontend stopped" || echo "Frontend was not running"
fi

echo ""
echo "Open Transcribe stopped."