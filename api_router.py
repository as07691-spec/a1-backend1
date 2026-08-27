from __future__ import annotations
import re
from typing import Any
from fastapi import APIRouter, HTTPException
from backtest import run_backtest as execute_backtest
from broker import BrokerError, PaperBroker
from indicators import TechnicalAnalysis
from smart_money import SmartMoneyDetector
router = APIRouter()
_SYMBOL_RE = re.compile(r"^[A-Z0-9.\-\u0600-\u06FF]{1,24}$")
def _normalize_symbol(symbol: str) -> str:
    value = (symbol or "").strip().upper()
    if not value or not _SYMBOL_RE.fullmatch(value):
        raise HTTPException(status_code=400, detail="نماد نامعتبر است")
    return value
detector = SmartMoneyDetector()
broker = PaperBroker()
def broker_http_error(exc: BrokerError) -> HTTPException:
    return HTTPException(
        status_code=exc.status_code,
        detail=exc.message,
    )
@router.get("/health")
async def health_check():
    return {
        "status": "ok",
        "service": "A1 Backend",
        "stage": 16,
        "message": "A1 Backend is operational",
        "broker": broker.status(),
    }
@router.get("/analyze/{symbol}")
async def analyze_symbol(symbol: str):
    symbol = _normalize_symbol(symbol)
    try:
        history = market_data_service.get_historical_data(symbol, "daily")
        rows = history["data"]
        if not rows:
            raise HTTPException(status_code=404, detail="No data available for symbol")
    except MarketDataError as exc:
        raise HTTPException(status_code=422, detail=str(exc))
    
    closes = [float(row["close"]) for row in rows]
    rsi_values = TechnicalAnalysis.calculate_rsi(closes, period=2)
    
    smart_rows = detector.detect_unusual_volume(rows, window=22)
    smart_rows = detector.detect_transaction_value(smart_rows)
    smart_rows = detector.detect_money_flow(smart_rows)
    
    last_rsi = rsi_values[-1] if rsi_values else None
    last_row = smart_rows[-1] if smart_rows else {}
    money_flow_ratio = detector.money_flow_ratio(smart_rows)
    is_smart_money_alert = detector.smart_money_alert(smart_rows)
    
    return {
        "symbol": symbol,
        "last_rsi": round(float(last_rsi), 2) if last_rsi is not None else None,
        "avg_volume": round(float(last_row.get("avg_volume", 0.0)), 2) if last_row else None,
        "is_unusual_volume": bool(last_row.get("is_unusual_volume", False)),
        "transaction_value_billion": round(float(last_row.get("transaction_value_billion", 0.0)), 4) if last_row else None,
        "money_flow_ratio": round(float(money_flow_ratio), 4),
        "smart_money_alert": bool(is_smart_money_alert),
        "engine": "python-stdlib",
    }
@router.post("/backtest")
async def backtest_endpoint(payload: dict):
    payload["symbol"] = _normalize_symbol(payload.get("symbol", ""))
    return execute_backtest(payload)
@router.get("/broker/status")
async def broker_status():
    return broker.status()
@router.post("/broker/orders")
async def submit_broker_order(payload: dict[str, Any]):
    try:
        return broker.submit_order(payload)
    except BrokerError as exc:
        raise broker_http_error(exc) from exc
@router.get("/broker/orders")
async def list_broker_orders(limit: int = 100):
    try:
        return {"orders": broker.list_orders(limit), "limit": limit}
    except BrokerError as exc:
        raise broker_http_error(exc) from exc
@router.get("/broker/orders/{order_id}")
async def get_broker_order(order_id: str):
    try:
        return broker.get_order(order_id)
    except BrokerError as exc:
        raise broker_http_error(exc) from exc
@router.get("/broker/account")
async def broker_account():
    return broker.account()
@router.get("/broker/positions")
async def broker_positions():
    return {"positions": broker.list_positions()}
@router.get("/broker/events")
async def broker_events(limit: int = 100):
    try:
        return {"events": broker.list_events(limit), "limit": limit}
    except BrokerError as exc:
        raise broker_http_error(exc) from exc
# === A1 STAGE 15 MARKET DATA ===
from fastapi import HTTPException as MarketHTTPException
from market_data import MarketDataError, MarketDataService
market_data_service = MarketDataService()
@router.get("/market/status")
async def market_status():
    return market_data_service.status()
@router.get("/market/quote/{symbol}")
async def market_quote(symbol: str):
    try:
        symbol = _normalize_symbol(symbol)
        return market_data_service.get_latest_quote(symbol)
    except MarketDataError as exc:
        raise MarketHTTPException(status_code=422, detail=str(exc)) from exc
@router.get("/market/history/{symbol}")
async def market_history(symbol: str, timeframe: str = "daily"):
    try:
        symbol = _normalize_symbol(symbol)
        return market_data_service.get_historical_data(symbol, timeframe)
    except MarketDataError as exc:
        raise MarketHTTPException(status_code=422, detail=str(exc)) from exc
@router.delete("/market/cache")
async def market_clear_cache():
    return market_data_service.clear_cache()
# === A1 STAGE 15 MARKET DATA END ===
