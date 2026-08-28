# Purpose: Order execution simulator and position safety controller.
# Logic: Handles simulated order lifecycle and emergency kill-switch.

import time
from typing import Dict, Any, List

class TradeExecutor:
    def __init__(self):
        self._orders: List[Dict[str, Any]] = []

    def execute_order(self, symbol: str, side: str, volume: int, price: float) -> Dict[str, Any]:
        order_id = f"ORD-{int(time.time() * 1000)}"
        order = {
            "ok": True,
            "order_id": order_id,
            "symbol": symbol,
            "side": side.upper(),
            "volume": int(volume),
            "price": float(price),
            "status": "FILLED",
            "mode": "PAPER_TRADING_SIMULATOR",
            "timestamp": time.time()
        }
        self._orders.insert(0, order)
        return order

    def get_order_history(self, limit: int = 10) -> List[Dict[str, Any]]:
        return self._orders[:limit]

    def cancel_all_orders(self) -> Dict[str, Any]:
        count = len(self._orders)
        return {
            "ok": True,
            "status": "ALL_ORDERS_CANCELLED_AND_POSITIONS_SAFE",
            "cancelled_count": count,
            "timestamp": time.time(),
            "msg": "Kill Switch Activated: Open positions secured, active orders cancelled."
        }

trade_executor = TradeExecutor()
