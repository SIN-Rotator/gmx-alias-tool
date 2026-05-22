# GMX Alias Tool

CLI + API to create, delete, and rotate GMX FreeMail aliases via CUA + Playwright + CDP.

## Prerequisites

- Chrome running with `--remote-debugging-port=9222`
- `--profile-directory="Profile 901"` (Jeremy profile, NOT simoneschulze)
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
| Verify | Playwright | `inp.input_value() == ''` (empty = created) |
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

## Verified: 2026-05-22
- 3/3 rotations successful, ~19.8s average
- Full Fireworks E2E: GMX alias → Fireworks signup → OTP → Login → Onboarding → API Key → Pool
- Latest API Key: `fw_MdM6tGucgWuuc7zQyJGeTK` (crystal-beetle-676@gmx.de)

## Critical Notes
- **Chrome Config**: `--user-data-dir="/Users/jeremy/Library/Application Support/Google Chrome"` with `--profile-directory="Profile 901"`
- **NO `--force-renderer-accessibility`**: GMX shows non-clickable rows with that flag
- **NO `pkill -9`**: Kills user Chrome — use SIGTERM via `kill`
- **E-Mail click**: `a:has-text("E-Mail")` → inbox with SID (no login needed if session cookie exists)
- **Alias delete**: `hover(force=True)` → `[title*="löschen"]` click(force=True) → CUA OK dialog
- **Alias create**: fill `input[type="text"]` → `button:has-text("Hinzufügen")` click → verify empty
