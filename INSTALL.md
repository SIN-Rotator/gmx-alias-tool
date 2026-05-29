# GMX Alias Tool — Installation

*CLI + FastAPI Server für GMX FreeMail Alias-Management. Prozedurale Schritt-für-Schritt-Anleitung.*

---

## 1. Voraussetzungen

### 1.1 Python 3.9+

```bash
python3 --version
# ✅ "Python 3.9.x" oder höher
# ❌ → `brew install python3`
```

### 1.2 Google Chrome

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --version
# ✅ "Google Chrome xxx"
```

### 1.3 Chrome Profil (Profile 901 — Jeremy)

```bash
ls "/Users/jeremy/Library/Application Support/Google Chrome/Profile 901"
# ✅ Verzeichnis existiert
# ❌ → Chrome starten, Profil 901 einrichten, einmal bei GMX einloggen
```

### 1.4 Sibling-Repo: SINator-fireworksai

Dieses Repo importiert `agent_toolbox.core.cdp_client` aus dem SINator-fireworksai Projekt.

```bash
ls ~/dev/SINator-fireworksai/agent_toolbox/core/cdp_client.py
# ✅ Datei existiert
# ❌ → `git clone git@github.com:SIN-Rotator/SINator-FireworksAI.git ~/dev/SINator-fireworksai`
```

### 1.5 cua-driver (optional — für Alias-Löschen-Dialog)

```bash
which cua-driver
# ✅ "/usr/local/bin/cua-driver" oder ähnlich
# ❌ → `pip install cua-driver` (falls verfügbar)
```

---

## 2. Repository klonen

```bash
cd ~/dev
git clone git@github.com:SIN-Rotator/gmx-alias-tool.git
cd gmx-alias-tool

# ✅ Du bist jetzt im Ordner ~/dev/gmx-alias-tool
```

---

## 3. Dependencies installieren

```bash
# Aus requirements.txt:
pip3 install -r requirements.txt
# ✅ Enthält: websockets>=12.0, fastapi>=0.109.0, uvicorn>=0.27.0, pydantic>=2.0

# Zusätzlich benötigt:
pip3 install playwright httpx
python3 -m playwright install chromium

# ✅ Keine Fehlermeldungen
```

---

## 4. Chrome starten (mit CDP)

**⚠️ Wichtig: `--force-renderer-accessibility` NICHT verwenden** — GMX zeigt dann nicht-clickbare Zeilen.

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --remote-debugging-port=9222 \
  --profile-directory="Profile 901" \
  --user-data-dir="/Users/jeremy/Library/Application Support/Google Chrome" \
  --no-first-run &

sleep 5
curl -s http://127.0.0.1:9222/json/version
# ✅ "Browser": "Chrome/..." — CDP ist ready
# ❌ "Connection refused" → Chrome nicht gestartet
```

---

## 5. cua-driver starten (optional)

Nötig für den Alias-Löschen-Bestätigungsdialog:

```bash
cua-driver serve &
# ✅ Daemon läuft im Hintergrund
```

---

## 6. Server starten (`:8001`)

```bash
python3 server.py
# → FastAPI Server auf http://0.0.0.0:8001
```

**In einem zweiten Terminal — Verifikation:**

```bash
curl http://localhost:8001/health
# ✅ {"status":"ok","chrome":true}
# ❌ "Connection refused" → Server läuft nicht
# ❌ chrome: false → Chrome CDP nicht erreichbar (Schritt 4)
```

---

## 7. CLI-Tool testen

```bash
# Session-Status prüfen:
python3 gmx_alias_tool.py status
# ✅ {"status": "ok", "gmx_session": true, ...}

# Detaillierte Session-Validierung:
python3 gmx_alias_tool.py check
# ✅ GMX Session ist aktiv

# Alias rotieren (löschen + neu erstellen):
python3 gmx_alias_tool.py rotate
# ✅ "Alias rotation complete: frost-tiger-342@gmx.de"

# Nur erstellen:
python3 gmx_alias_tool.py create
# ✅ "Alias created: crisp-fox-871@gmx.de"

# Nur löschen:
python3 gmx_alias_tool.py delete
# ✅ "Alias deleted"
```

---

## 8. API testen

```bash
# Alias rotieren:
curl -X POST http://localhost:8001/alias/rotate
# ✅ {"status":"success","alias":"crystal-beetle-676@gmx.de"}

# Alias erstellen:
curl -X POST "http://localhost:8001/alias/create?alias_name=test-user-42"
# ✅ {"status":"success","alias":"test-user-42@gmx.de"}

# Session prüfen:
curl -X POST http://localhost:8001/session/check
# ✅ {"status":"ok","gmx_session":true}
```

---

## 9. Cloudflare Tunnel (optional — Remote-Zugriff)

```bash
./start.sh
# Startet Server + Tunnel
# ✅ "Public URL: https://xxx.trycloudflare.com"
```

---

## 10. Verifikation — alles läuft?

```bash
python3 -c "
import urllib.request, json

ok, fail = [], []

try:
    r = urllib.request.urlopen('http://localhost:8001/health', timeout=5)
    data = json.loads(r.read())
    if data.get('chrome'):
        ok.append('Server :8001 — ok (Chrome connected)')
    else:
        fail.append('Server :8001 — Chrome disconnected')
except Exception as e:
    fail.append(f'Server :8001 — {e}')

try:
    r = urllib.request.urlopen('http://127.0.0.1:9222/json/version', timeout=5)
    ok.append('Chrome CDP :9222 — ok')
except Exception as e:
    fail.append(f'Chrome CDP :9222 — {e}')

try:
    r = urllib.request.urlopen('http://localhost:8001/session/check', timeout=10)
    data = json.loads(r.read())
    if data.get('gmx_session'):
        ok.append('GMX Session — aktiv')
    else:
        fail.append('GMX Session — tot')
except Exception as e:
    fail.append(f'GMX Session — {e}')

print('✅ Alles OK' if not fail else '❌ Fehler:')
for m in ok: print(f'  ✅ {m}')
for m in fail: print(f'  ❌ {m}')
"

# ✅ Alles OK
#   ✅ Server :8001 — ok (Chrome connected)
#   ✅ Chrome CDP :9222 — ok
#   ✅ GMX Session — aktiv
```

---

## 11. Fehlerbehebung

| Problem | Ursache | Lösung |
|---------|---------|--------|
| `Connection refused` auf `:8001` | Server läuft nicht | `python3 server.py` starten |
| `chrome: false` | Chrome ohne CDP | Schritt 4 wiederholen |
| `GMX session dead` | Cookie abgelaufen | GMX im Browser manuell einloggen |
| `ImportError: cdp_client` | SINator-fireworksai fehlt | `ls ~/dev/SINator-fireworksai/...` prüfen (Schritt 1.4) |
| Alias-Löschen hängt | cua-driver läuft nicht | `cua-driver serve &` |
| CAPTCHA bei GMX | Session ungültig | Profile 901 manuell bei GMX einloggen |
| `--force-renderer-accessibility` | Chrome Flag killt Klicks | Ohne das Flag starten |

---

*Stand: 2026-05-29 | FastAPI | CDP + CUA + Playwright Hybrid | Chrome Profile 901*
