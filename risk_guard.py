import os
import json
from typing import Dict, Any

class PortfolioRiskGuard:
    def __init__(self, max_drawdown_pct: float = 5.0, max_single_pos_pct: float = 25.0):
        self.max_drawdown_pct = max_drawdown_pct
        self.max_single_pos_pct = max_single_pos_pct

    def evaluate_order(self, order_val: float, total_portfolio: float) -> Dict[str, Any]:
        if total_portfolio <= 0:
            return {"allowed": False, "reason": "Invalid portfolio total value"}
        
        pos_pct = (order_val / total_portfolio) * 100.0
        if pos_pct > self.max_single_pos_pct:
            return {
                "allowed": False,
                "reason": f"Position size ({pos_pct:.1f}%) exceeds single allocation limit ({self.max_single_pos_pct}%)"
            }
        return {"allowed": True, "risk_score": round(pos_pct / self.max_single_pos_pct, 2)}

risk_guard = PortfolioRiskGuard()
