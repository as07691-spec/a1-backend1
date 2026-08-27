"""A1 — مدلهای اعتبارسنجی داده."""
from pydantic import BaseModel
from typing import Optional

class HealthResponse(BaseModel):
    status: str
    app: str
    version: str
    uptime_s: float

class Instrument(BaseModel):
    symbol: str
    last_price: float
    close_price: float
    open_price: float
    high_price: float
    low_price: float
    volume: int
    value: int
    change_pct: Optional[float] = None

class PortfolioItem(BaseModel):
    symbol: str
    quantity: float
    avg_cost: float

class Portfolio(BaseModel):
    items: list[PortfolioItem]
    total_value: float
    total_gain_pct: float
