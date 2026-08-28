"""
Portfolio Management Engine for A1 Agent.
Handles position tracking, valuation, cash allocation, and PnL calculation.
"""
from typing import Dict, Any, List
from pydantic import BaseModel, Field
import datetime

class Position(BaseModel):
    symbol: str
    quantity: int
    average_buy_price: float
    current_price: float
    market_value: float = 0.0
    unrealized_pnl: float = 0.0
    pnl_percentage: float = 0.0

class PortfolioSummary(BaseModel):
    total_value: float
    cash_balance: float
    invested_capital: float
    total_unrealized_pnl: float
    total_return_pct: float
    positions_count: int
    updated_at: str

class PortfolioManager:
    """Manages active trading positions and cash reserves."""

    def __init__(self, initial_cash: float = 100_000_000.0):
        self.cash_balance = initial_cash
        self.positions: Dict[str, Dict[str, Any]] = {
            "فولاد": {
                "quantity": 10000,
                "average_buy_price": 5200.0,
                "current_price": 5450.0
            },
            "خودرو": {
                "quantity": 25000,
                "average_buy_price": 3100.0,
                "current_price": 2980.0
            },
            "شستا": {
                "quantity": 15000,
                "average_buy_price": 1250.0,
                "current_price": 1320.0
            }
        }

    def get_positions(self) -> List[Position]:
        """Calculates current metrics for each position."""
        result = []
        for symbol, data in self.positions.items():
            qty = data["quantity"]
            avg_p = data["average_buy_price"]
            curr_p = data["current_price"]
            mv = qty * curr_p
            cost = qty * avg_p
            pnl = mv - cost
            pnl_pct = ((curr_p - avg_p) / avg_p * 100.0) if avg_p > 0 else 0.0

            result.append(
                Position(
                    symbol=symbol,
                    quantity=qty,
                    average_buy_price=round(avg_p, 2),
                    current_price=round(curr_p, 2),
                    market_value=round(mv, 2),
                    unrealized_pnl=round(pnl, 2),
                    pnl_percentage=round(pnl_pct, 2)
                )
            )
        return result

    def get_summary(self) -> PortfolioSummary:
        """Calculates total portfolio valuation and overall returns."""
        positions = self.get_positions()
        invested = sum(p.quantity * p.average_buy_price for p in positions)
        market_val = sum(p.market_value for p in positions)
        total_pnl = market_val - invested
        total_val = self.cash_balance + market_val
        ret_pct = (total_pnl / invested * 100.0) if invested > 0 else 0.0

        return PortfolioSummary(
            total_value=round(total_val, 2),
            cash_balance=round(self.cash_balance, 2),
            invested_capital=round(invested, 2),
            total_unrealized_pnl=round(total_pnl, 2),
            total_return_pct=round(ret_pct, 2),
            positions_count=len(positions),
            updated_at=datetime.datetime.now(datetime.timezone.utc).isoformat()
        )

portfolio_engine = PortfolioManager()
