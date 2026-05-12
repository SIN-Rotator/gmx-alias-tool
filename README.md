# GMX Alias Tool

CLI + API to create, delete, and rotate GMX FreeMail aliases via Chrome CDP.

## Prerequisites

- Chrome running with `--remote-debugging-port=9222`
- Python 3.9+
- [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/) (for remote access)

## Quick Start

```bash
pip install -r requirements.txt
./start.sh
```

This starts the API server on port 8001 + a Cloudflare Tunnel with a public URL.

The tunnel URL is saved to `.tunnel_url` and displayed on startup.

## CLI Usage

```bash
python gmx_alias_tool.py status    # Check GMX session
python gmx_alias_tool.py check     # Detailed session check
python gmx_alias_tool.py rotate    # Rotate alias (delete + create)
python gmx_alias_tool.py create    # Create alias (auto-generated name)
python gmx_alias_tool.py delete    # Delete existing alias
```

## API Server

```bash
# Manual start without tunnel
python server.py
```

Endpoints on `http://localhost:8001`:

| Method | Path | Description |
|--------|------|-------------|
| POST | `/alias/create` | Create new alias |
| POST | `/alias/delete` | Delete existing alias |
| POST | `/alias/rotate` | Delete + create alias |
| POST | `/session/check` | Check GMX session |
| GET | `/health` | Health check |

### Using via Cloudflare Tunnel

After `./start.sh`, use the tunnel URL for remote access:

```bash
TUNNEL_URL=$(cat .tunnel_url)
curl $TUNNEL_URL/health
curl -X POST $TUNNEL_URL/alias/rotate -H "Content-Type: application/json" -d '{}'
curl -X POST $TUNNEL_URL/alias/create -H "Content-Type: application/json" -d '{"alias_name": "my-alias-123"}'
curl -X POST $TUNNEL_URL/alias/delete
```

## Management

```bash
./start.sh              # Start server + tunnel
./start.sh stop         # Stop server + tunnel
./start.sh tunnel-only  # Restart only the tunnel
```
