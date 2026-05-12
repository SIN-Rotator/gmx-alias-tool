#!/bin/bash
# GMX Alias Tool — Auto-Start mit Cloudflare Tunnel
# Startet Server auf Port 8001 + Cloudflare Tunnel für externen Zugriff

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$SCRIPT_DIR/.server.pid"
TUNNEL_PID_FILE="$SCRIPT_DIR/.tunnel.pid"
TUNNEL_LOG="$SCRIPT_DIR/.tunnel.log"
TUNNEL_URL_FILE="$SCRIPT_DIR/.tunnel_url"

stop_old() {
    if [ -f "$PID_FILE" ]; then
        kill $(cat "$PID_FILE") 2>/dev/null && echo "Old server stopped"
        rm -f "$PID_FILE"
    fi
    if [ -f "$TUNNEL_PID_FILE" ]; then
        kill $(cat "$TUNNEL_PID_FILE") 2>/dev/null && echo "Old tunnel stopped"
        rm -f "$TUNNEL_PID_FILE"
    fi
}

case "${1:-start}" in
    stop)
        stop_old
        exit 0
        ;;
    tunnel-only)
        echo "Starting Cloudflare Tunnel only (server must be running on port 8001)..."
        stop_old
        nohup cloudflared tunnel --url http://localhost:8001 > "$TUNNEL_LOG" 2>&1 &
        echo $! > "$TUNNEL_PID_FILE"
        sleep 5
        TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' "$TUNNEL_LOG" | head -1)
        if [ -n "$TUNNEL_URL" ]; then
            echo "$TUNNEL_URL" > "$TUNNEL_URL_FILE"
            echo "✅ Tunnel: $TUNNEL_URL → http://localhost:8001"
            echo "   API:  $TUNNEL_URL/alias/rotate"
            echo "   Docs: $TUNNEL_URL/docs"
        fi
        exit 0
        ;;
    *)
        ;;
esac

stop_old
sleep 1

echo "Starting GMX Alias Tool server on port 8001..."
cd "$SCRIPT_DIR"
nohup python3 server.py > /tmp/gmx-alias-server.log 2>&1 &
echo $! > "$PID_FILE"
sleep 3

if ! kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "❌ Server failed to start. Check /tmp/gmx-alias-server.log"
    cat /tmp/gmx-alias-server.log
    exit 1
fi

echo "✅ Server running on http://localhost:8001"

echo "Starting Cloudflare Tunnel..."
nohup cloudflared tunnel --url http://localhost:8001 > "$TUNNEL_LOG" 2>&1 &
echo $! > "$TUNNEL_PID_FILE"
sleep 5

TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' "$TUNNEL_LOG" | head -1)
if [ -n "$TUNNEL_URL" ]; then
    echo "$TUNNEL_URL" > "$TUNNEL_URL_FILE"
    echo ""
    echo "═════════════════════════════════════════════════════════"
    echo "  🚀 GMX Alias Tool running!"
    echo "  Local:  http://localhost:8001"
    echo "  Remote: $TUNNEL_URL"
    echo "  Docs:   $TUNNEL_URL/docs"
    echo "  Health: curl $TUNNEL_URL/health"
    echo "═════════════════════════════════════════════════════════"
else
    echo "⚠️  Tunnel URL not found yet. Check $TUNNEL_LOG"
    echo "   Local API: http://localhost:8001"
    echo "   To restart tunnel: $0 tunnel-only"
fi
