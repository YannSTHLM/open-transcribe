#!/bin/bash
# Open Transcribe - Stop both servers
# Kills servers by PID and also by port as fallback

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PID_DIR="$APP_DIR/.pids"

echo "Stopping Open Transcribe..."

# -------------------------------------------------------
# Stop backend
# -------------------------------------------------------
if [ -f "$PID_DIR/backend.pid" ]; then
    BACKEND_PID=$(cat "$PID_DIR/backend.pid")
    if kill -0 "$BACKEND_PID" 2>/dev/null; then
        # Kill the entire process tree
        pkill -P "$BACKEND_PID" 2>/dev/null || true
        kill -TERM "$BACKEND_PID" 2>/dev/null
        # Wait up to 5s for graceful shutdown
        for i in 1 2 3 4 5; do
            kill -0 "$BACKEND_PID" 2>/dev/null || break
            sleep 1
        done
        # Force kill if still running
        kill -9 "$BACKEND_PID" 2>/dev/null || true
        echo "Backend stopped (PID $BACKEND_PID)"
    else
        echo "Backend was not running"
    fi
    rm -f "$PID_DIR/backend.pid"
fi

# Fallback: kill anything on port 8000
lsof -ti:8000 2>/dev/null | while read pid; do
    kill -TERM "$pid" 2>/dev/null || true
done

# -------------------------------------------------------
# Stop frontend
# -------------------------------------------------------
if [ -f "$PID_DIR/frontend.pid" ]; then
    FRONTEND_PID=$(cat "$PID_DIR/frontend.pid")
    if kill -0 "$FRONTEND_PID" 2>/dev/null; then
        # Kill the entire process tree (npm + node children)
        pkill -P "$FRONTEND_PID" 2>/dev/null || true
        kill -TERM "$FRONTEND_PID" 2>/dev/null
        # Wait up to 5s for graceful shutdown
        for i in 1 2 3 4 5; do
            kill -0 "$FRONTEND_PID" 2>/dev/null || break
            sleep 1
        done
        # Force kill if still running
        kill -9 "$FRONTEND_PID" 2>/dev/null || true
        echo "Frontend stopped (PID $FRONTEND_PID)"
    else
        echo "Frontend was not running"
    fi
    rm -f "$PID_DIR/frontend.pid"
fi

# Fallback: kill anything on port 5173
lsof -ti:5173 2>/dev/null | while read pid; do
    kill -TERM "$pid" 2>/dev/null || true
done

# -------------------------------------------------------
# Clean up stale PIDs and logs
# -------------------------------------------------------
rm -f "$PID_DIR/backend.log" "$PID_DIR/frontend.log" 2>/dev/null

echo ""
echo "Open Transcribe stopped."