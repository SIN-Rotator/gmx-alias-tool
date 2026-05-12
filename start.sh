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

stop_tunnel_only() {
    if [ -f "$TUNNEL_PID_FILE" ]; then
        kill $(cat "$TUNNEL_PID_FILE") 2>/dev/null && echo "Old tunnel stopped"
        rm -f "$TUNNEL_PID_FILE"
    fi
}

extract_tunnel_url() {
    cloudflared tunnel --url http://localhost:8001 2>&1 | while IFS= read -r line; do
        echo "$line" >> "$TUNNEL_LOG"
        TURL=$(echo "$line" | grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' | head -1)
        if [ -n "$TURL" ]; then
            echo "$TURL" > "$TUNNEL_URL_FILE"
            echo "$TURL"
            break
        fi
    done
}

case "${1:-start}" in
    stop)
        stop_old
        exit 0
        ;;
    tunnel-only)
        echo "Starting Cloudflare Tunnel (server must already be running on port 8001)..."
        stop_tunnel_only
        extract_tunnel_url &
        TUNNEL_PID=$!
        echo $TUNNEL_PID > "$TUNNEL_PID_FILE"
        sleep 5
        if [ -f "$TUNNEL_URL_FILE" ]; then
            TURL=$(cat "$TUNNEL_URL_FILE")
            echo "✅ Tunnel: $TURL → http://localhost:8001"
        else
            echo "⏳ Tunnel starting... URL saved to $TUNNEL_URL_FILE when ready"
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
extract_tunnel_url &
TUNNEL_PID=$!
echo $TUNNEL_PID > "$TUNNEL_PID_FILE"
sleep 5

if [ -f "$TUNNEL_URL_FILE" ]; then
    TUNNEL_URL=$(cat "$TUNNEL_URL_FILE")
    echo ""
    echo "═════════════════════════════════════════════════════════"
    echo "  🚀 GMX Alias Tool running!"
    echo "  Local:  http://localhost:8001"
    echo "  Remote: $TUNNEL_URL"
    echo "  Docs:   $TUNNEL_URL/docs"
    echo "═════════════════════════════════════════════════════════"
else
    echo "⚠️  Waiting for tunnel URL... Check $TUNNEL_URL_FILE"
    echo "   Local API: http://localhost:8001"
fi
