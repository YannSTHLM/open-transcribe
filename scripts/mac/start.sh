#!/bin/bash
# Open Transcribe - Start both servers
# Starts the backend (uvicorn) and frontend (vite) servers
#
# Usage:
#   ./start.sh              - Start servers, wait, open browser
#   ./start.sh --daemon     - Start servers in background, exit immediately
#   ./start.sh --no-wait    - Start servers, don't wait (for .app bundle)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PID_DIR="$APP_DIR/.pids"
DAEMON_MODE=false
NO_WAIT=false

for arg in "$@"; do
    case "$arg" in
        --daemon) DAEMON_MODE=true ;;
        --no-wait) NO_WAIT=true ;;
    esac
done

mkdir -p "$PID_DIR"

# -------------------------------------------------------
# Check if already running
# -------------------------------------------------------
if [ -f "$PID_DIR/backend.pid" ] && kill -0 "$(cat "$PID_DIR/backend.pid")" 2>/dev/null; then
    echo "Backend server is already running (PID $(cat "$PID_DIR/backend.pid"))"
else
    echo "Starting backend server..."
    cd "$APP_DIR/backend"
    source venv/bin/activate
    
    if [ "$DAEMON_MODE" = true ]; then
        nohup python3 -m app.main > "$PID_DIR/backend.log" 2>&1 &
    else
        python3 -m app.main &
    fi
    BACKEND_PID=$!
    echo "$BACKEND_PID" > "$PID_DIR/backend.pid"
    disown "$BACKEND_PID" 2>/dev/null || true
    echo "Backend started (PID $BACKEND_PID) on http://localhost:8000"
fi

if [ -f "$PID_DIR/frontend.pid" ] && kill -0 "$(cat "$PID_DIR/frontend.pid")" 2>/dev/null; then
    echo "Frontend server is already running (PID $(cat "$PID_DIR/frontend.pid"))"
else
    echo "Starting frontend server..."
    cd "$APP_DIR/frontend"
    
    if [ "$DAEMON_MODE" = true ]; then
        nohup npm run dev > "$PID_DIR/frontend.log" 2>&1 &
    else
        npm run dev &
    fi
    FRONTEND_PID=$!
    echo "$FRONTEND_PID" > "$PID_DIR/frontend.pid"
    disown "$FRONTEND_PID" 2>/dev/null || true
    echo "Frontend started (PID $FRONTEND_PID) on http://localhost:5173"
fi

# In daemon mode, just exit after starting
if [ "$DAEMON_MODE" = true ]; then
    echo "Servers starting in daemon mode..."
    exit 0
fi

# -------------------------------------------------------
# Wait for servers to be ready
# -------------------------------------------------------
if [ "$NO_WAIT" != true ]; then
    echo ""
    echo "Waiting for servers to be ready..."

    MAX_WAIT=30
    WAITED=0
    while ! curl -s http://localhost:8000/api/v1/health > /dev/null 2>&1; do
        sleep 1
        WAITED=$((WAITED + 1))
        if [ $WAITED -ge $MAX_WAIT ]; then
            echo "Warning: Backend server did not start within ${MAX_WAIT}s"
            break
        fi
    done

    if [ $WAITED -lt $MAX_WAIT ]; then
        echo "Backend is ready!"
    fi

    WAITED=0
    while ! curl -s http://localhost:5173 > /dev/null 2>&1; do
        sleep 1
        WAITED=$((WAITED + 1))
        if [ $WAITED -ge $MAX_WAIT ]; then
            echo "Warning: Frontend server did not start within ${MAX_WAIT}s"
            break
        fi
    done

    if [ $WAITED -lt $MAX_WAIT ]; then
        echo "Frontend is ready!"
    fi

    echo ""
    echo "╔══════════════════════════════════════╗"
    echo "║   Open Transcribe is running! 🎙️    ║"
    echo "╚══════════════════════════════════════╝"
    echo ""
    echo "  Frontend: http://localhost:5173"
    echo "  Backend:  http://localhost:8000"
    echo "  API Docs: http://localhost:8000/docs"
    echo ""

    # Open browser
    open http://localhost:5173

    # Keep script running if called directly
    echo "Press Ctrl+C to stop the servers."
    wait
fi