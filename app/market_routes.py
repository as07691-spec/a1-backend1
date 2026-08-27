import os
import json
from fastapi import APIRouter
from fastapi.responses import JSONResponse

router = APIRouter(prefix="/api/market", tags=["market"])
SNAPSHOT_FILE = "/opt/a1/backend/data/market_snapshot.json"

@router.get("/snapshot")
def get_market_snapshot():
    if not os.path.exists(SNAPSHOT_FILE):
        return JSONResponse(
            status_code=404,
            content={"ok": False, "message": "Market snapshot not found"}
        )
    try:
        with open(SNAPSHOT_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        return JSONResponse(status_code=200, content={"ok": True, "data": data})
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"ok": False, "message": f"Error reading snapshot: {str(e)}"}
        )
