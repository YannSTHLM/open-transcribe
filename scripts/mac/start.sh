#!/bin/bash
# Open Transcribe - Start both servers
# Starts the backend (uvicorn) and frontend (vite) servers

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PID_DIR="$APP_DIR/.pids"

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
    python3 -m app.main &
    BACKEND_PID=$!
    echo "$BACKEND_PID" > "$PID_DIR/backend.pid"
    echo "Backend started (PID $BACKEND_PID) on http://localhost:8000"
fi

if [ -f "$PID_DIR/frontend.pid" ] && kill -0 "$(cat "$PID_DIR/frontend.pid")" 2>/dev/null; then
    echo "Frontend server is already running (PID $(cat "$PID_DIR/frontend.pid"))"
else
    echo "Starting frontend server..."
    cd "$APP_DIR/frontend"
    npm run dev &
    FRONTEND_PID=$!
    echo "$FRONTEND_PID" > "$PID_DIR/frontend.pid"
    echo "Frontend started (PID $FRONTEND_PID) on http://localhost:5173"
fi

# -------------------------------------------------------
# Wait for servers to be ready, then open browser
# -------------------------------------------------------
echo ""
echo "Waiting for servers to be ready..."

# Wait for backend
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

# Wait for frontend
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

# Keep script running if called directly (not from .app)
if [ "${1:-}" != "--no-wait" ]; then
    echo "Press Ctrl+C to stop the servers."
    wait
fi