"""
Risk Management Engine for A1 Agent.
Performs pre-trade validation, exposure monitoring, and portfolio risk analysis.
"""
from typing import Dict, Any, Optional
from pydantic import BaseModel

class RiskCheckRequest(BaseModel):
    symbol: str
    side: str
    quantity: int
    price: float

class RiskCheckResult(BaseModel):
    passed: bool
    risk_score: float
    max_allowed_order_value: float
    order_value: float
    reasons: list[str]

class RiskEngine:
    """Evaluates orders and portfolio exposure limits."""

    def __init__(self, max_order_limit: float = 500_000_000.0, max_symbol_allocation_pct: float = 35.0):
        self.max_order_limit = max_order_limit
        self.max_symbol_allocation_pct = max_symbol_allocation_pct

    def evaluate_order(self, symbol: str, side: str, quantity: int, price: float, total_portfolio_value: float) -> RiskCheckResult:
        order_val = float(quantity) * float(price)
        reasons = []
        passed = True

        if order_val <= 0:
            passed = False
            reasons.append("ارزش سفارش باید بیشتر از صفر باشد.")

        if order_val > self.max_order_limit:
            passed = False
            reasons.append(f"ارزش سفارش از حد مجاز یک سفارش ({self.max_order_limit:,.0f} ریال) فراتر رفته است.")

        if total_portfolio_value > 0:
            allocation = (order_val / total_portfolio_value) * 100.0
            if allocation > self.max_symbol_allocation_pct and side.upper() == "BUY":
                passed = False
                reasons.append(f"تخصیص نماد ({allocation:.1f}٪) بیش از سقف مجاز ({self.max_symbol_allocation_pct}٪) است.")

        risk_score = min(100.0, max(5.0, (order_val / (self.max_order_limit or 1.0)) * 100.0))

        return RiskCheckResult(
            passed=passed,
            risk_score=round(risk_score, 2),
            max_allowed_order_value=self.max_order_limit,
            order_value=round(order_val, 2),
            reasons=reasons
        )

risk_engine = RiskEngine()
