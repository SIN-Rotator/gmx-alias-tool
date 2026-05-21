# GMX Alias Tool

CLI + API to create, delete, and rotate GMX FreeMail aliases via CUA + Playwright + CDP.

## Prerequisites

- Chrome running with `--remote-debugging-port=9222`
- Python 3.9+
- `cua-driver` daemon running
- `playwright` installed (`pip install playwright`)
- [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/) (for remote access)

## Architecture

| Component | Tool | Purpose |
|-----------|------|---------|
| Navigation | CUA | E-Mail → Einstellungen click |
| Delete | Playwright (iframe) | Hover alias → click delete icon |
| Delete confirm | CUA | OK button in dialog |
| Create | Playwright (iframe) | Fill input → click Hinzufügen |
| Verify | Playwright | `inp.input_value() == ''` |
| Session | CDP | SID extraction, cookie management |

## Quick Start

```bash
pip install -r requirements.txt playwright
playwright install chromium
cua-driver serve &
./start.sh
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/alias/create` | Create new alias (auto-generate or specify name) |
| POST | `/alias/delete` | Delete existing alias |
| POST | `/alias/rotate` | Delete + create alias |
| POST | `/session/check` | Check GMX session |
| GET | `/health` | Health check |

## Verified: 2026-05-21
- 3/3 rotations successful, ~19.8s average
- Full Fireworks flow: GMX alias → Fireworks signup → OTP → Login → API Key
