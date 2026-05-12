# GMX Alias Tool

CLI + API to create, delete, and rotate GMX FreeMail aliases via Chrome CDP.

## Prerequisites

- Chrome running with `--remote-debugging-port=9222`
- Python 3.9+

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
pip install -r requirements.txt
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
