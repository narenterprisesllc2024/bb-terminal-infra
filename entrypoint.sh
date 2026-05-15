#!/bin/bash
# BB-Terminal entrypoint — launches OpenBB API (port 6900) + Vite preview (port 5173) in parallel.
set -e
cd /app/src

# Start OpenBB API in background
echo "[entrypoint] Starting OpenBB API on :6900..."
openbb-api --host 0.0.0.0 --port 6900 &
API_PID=$!

# Wait briefly for API to come up
sleep 5

# Build + start Vite preview server
echo "[entrypoint] Building Vite frontend..."
cd /app/src/app
npm run build

echo "[entrypoint] Starting Vite preview on :5173..."
npm run preview -- --host 0.0.0.0 --port 5173 &
UI_PID=$!

# Trap and forward signals
trap 'kill -TERM $API_PID $UI_PID 2>/dev/null' TERM INT

# Wait for either to exit
wait -n $API_PID $UI_PID
EXIT_CODE=$?
kill $API_PID $UI_PID 2>/dev/null || true
exit $EXIT_CODE
