from fastapi import APIRouter
from fastapi.responses import JSONResponse
from app.ai_engine import ai_core

router = APIRouter(prefix="/api/ai", tags=["ai"])

@router.get("/status")
def get_ai_status():
    return JSONResponse(content={"ok": True, "agent_status": ai_core.status})

@router.post("/analyze-market")
def trigger_market_analysis():
    result = ai_core.analyze_market_state()
    status_code = 200 if result.get("ok") else 503
    return JSONResponse(status_code=status_code, content=result)
