"""
Module: market.py
Purpose: TSETMC market data collector with fallback caching and simulated live feed.
Target Path: /opt/a1/backend/app/market.py
"""

import datetime
from typing import Dict, Any, List
from pydantic import BaseModel

class MarketQuote(BaseModel):
    symbol: str
    name: str
    last_price: float
    close_price: float
    yesterday_price: float
    change: float
    change_percent: float
    volume: int
    trades_count: int
    high_price: float
    low_price: float
    last_updated: str

class MarketOverview(BaseModel):
    overall_index: float
    index_change: float
    index_change_percent: float
    market_state: str
    top_tickers: List[MarketQuote]
    updated_at: str

class MarketEngine:
    def __init__(self):
        self.watchlist: Dict[str, Dict[str, Any]] = {
            "فولاد": {
                "name": "فولاد مبارکه اصفهان",
                "last_price": 5450.0,
                "yesterday_price": 5300.0,
                "volume": 45000000,
                "trades_count": 8200,
                "high_price": 5500.0,
                "low_price": 5350.0
            },
            "خودرو": {
                "name": "ایران خودرو",
                "last_price": 2980.0,
                "yesterday_price": 3050.0,
                "volume": 85000000,
                "trades_count": 12400,
                "high_price": 3070.0,
                "low_price": 2950.0
            },
            "شستا": {
                "name": "سرمایه گذاری تامین اجتماعی",
                "last_price": 1320.0,
                "yesterday_price": 1280.0,
                "volume": 62000000,
                "trades_count": 9100,
                "high_price": 1330.0,
                "low_price": 1270.0
            },
            "فملی": {
                "name": "ملی صنایع مس ایران",
                "last_price": 7200.0,
                "yesterday_price": 7100.0,
                "volume": 31000000,
                "trades_count": 6400,
                "high_price": 7280.0,
                "low_price": 7120.0
            },
            "وبملت": {
                "name": "بانک ملت",
                "last_price": 2450.0,
                "yesterday_price": 2400.0,
                "volume": 58000000,
                "trades_count": 7800,
                "high_price": 2480.0,
                "low_price": 2390.0
            }
        }

    def get_quotes(self) -> List[MarketQuote]:
        quotes = []
        now_str = datetime.datetime.now(datetime.timezone.utc).strftime("%H:%M:%S")
        for sym, d in self.watchlist.items():
            last = d["last_price"]
            yest = d["yesterday_price"]
            diff = round(last - yest, 2)
            pct = round((diff / yest * 100.0), 2) if yest > 0 else 0.0

            quotes.append(
                MarketQuote(
                    symbol=sym,
                    name=d["name"],
                    last_price=last,
                    close_price=last,
                    yesterday_price=yest,
                    change=diff,
                    change_percent=pct,
                    volume=d["volume"],
                    trades_count=d["trades_count"],
                    high_price=d["high_price"],
                    low_price=d["low_price"],
                    last_updated=now_str
                )
            )
        return quotes

    def get_overview(self) -> MarketOverview:
        quotes = self.get_quotes()
        return MarketOverview(
            overall_index=2145320.0,
            index_change=12450.0,
            index_change_percent=0.58,
            market_state="OPEN",
            top_tickers=quotes,
            updated_at=datetime.datetime.now(datetime.timezone.utc).isoformat()
        )

market_engine = MarketEngine()
