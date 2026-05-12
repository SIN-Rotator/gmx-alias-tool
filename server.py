import time, logging, asyncio
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from gmx_service import GmxService, get_gmx_service
from cdp_client import get_browser_ws_endpoint
from schemas import (
    GmxAliasCreateRequest, GmxAliasResponse,
    GmxSessionCheckResponse, GmxAliasDeleteResponse,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="GMX Alias Tool", version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

CDP_PORT = 9222

async def _ensure_browser(cdp_port: int = CDP_PORT):
    try:
        ws = await get_browser_ws_endpoint(cdp_port)
        return ws, cdp_port
    except Exception:
        raise HTTPException(status_code=400, detail=f"Chrome nicht auf Port {cdp_port}. Starten: Chrome mit --remote-debugging-port={cdp_port}")

@app.get("/health")
async def health():
    try:
        await get_browser_ws_endpoint(CDP_PORT)
        return {"status": "healthy", "cdp_port": CDP_PORT}
    except:
        return {"status": "no_browser", "cdp_port": CDP_PORT}

@app.post("/alias/create", response_model=GmxAliasResponse)
async def alias_create(request: GmxAliasCreateRequest):
    t0 = time.time()
    await _ensure_browser()
    try:
        svc = get_gmx_service()
        svc.email = "opensin@gmx.de"
        svc.password = "ZOE.jerry2024"
        if request.delete_existing:
            await svc.delete_existing_alias(cdp_port=CDP_PORT)
        result = await svc.create_alias(alias_name=request.alias_name, cdp_port=CDP_PORT)
        return GmxAliasResponse(
            status=result.get("status", "error"),
            alias_email=result.get("alias_email"),
            alias_name=result.get("alias_name"),
            steps_completed=result.get("steps_completed", []),
            steps_failed=result.get("steps_failed", []),
            execution_time=f"{time.time()-t0:.2f}s",
            error=result.get("error"),
        )
    except Exception as e:
        return GmxAliasResponse(status="error", execution_time=f"{time.time()-t0:.2f}s", error=str(e))

@app.post("/alias/delete", response_model=GmxAliasDeleteResponse)
async def alias_delete():
    t0 = time.time()
    await _ensure_browser()
    try:
        svc = get_gmx_service()
        svc.email = "opensin@gmx.de"
        svc.password = "ZOE.jerry2024"
        result = await svc.delete_existing_alias(cdp_port=CDP_PORT)
        return GmxAliasDeleteResponse(
            status=result.get("status", "error"),
            deleted=result.get("deleted", False),
            alias=result.get("alias"),
            execution_time=f"{time.time()-t0:.2f}s",
            error=result.get("error"),
        )
    except Exception as e:
        return GmxAliasDeleteResponse(status="error", execution_time=f"{time.time()-t0:.2f}s", error=str(e))

@app.post("/alias/rotate", response_model=GmxAliasResponse)
async def alias_rotate(request: GmxAliasCreateRequest):
    t0 = time.time()
    await _ensure_browser()
    try:
        svc = get_gmx_service()
        svc.email = "opensin@gmx.de"
        svc.password = "ZOE.jerry2024"
        result = await svc.rotate_alias(new_alias_name=request.alias_name, cdp_port=CDP_PORT)
        return GmxAliasResponse(
            status=result.get("status", "error"),
            alias_email=result.get("created_alias"),
            alias_name=result.get("created_alias_name"),
            steps_completed=result.get("steps_completed", []),
            steps_failed=result.get("steps_failed", []),
            execution_time=f"{time.time()-t0:.2f}s",
            error=result.get("error"),
        )
    except Exception as e:
        return GmxAliasResponse(status="error", execution_time=f"{time.time()-t0:.2f}s", error=str(e))

@app.post("/session/check", response_model=GmxSessionCheckResponse)
async def session_check():
    t0 = time.time()
    await _ensure_browser()
    try:
        svc = get_gmx_service()
        svc.email = "opensin@gmx.de"
        svc.password = "ZOE.jerry2024"
        result = await svc.check_session(cdp_port=CDP_PORT)
        return GmxSessionCheckResponse(
            status=result.get("status", "unknown"),
            current_url=result.get("current_url", ""),
            session_active=result.get("session_active", False),
            execution_time=f"{time.time()-t0:.2f}s",
            error=result.get("error"),
        )
    except Exception as e:
        return GmxSessionCheckResponse(status="error", current_url="", session_active=False, execution_time=f"{time.time()-t0:.2f}s", error=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
