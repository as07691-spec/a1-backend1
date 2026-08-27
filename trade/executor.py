import os
import json
import time
from typing import Dict, Any

ORDERS_FILE = "/opt/a1/backend/data/orders_history.jsonl"

class TradeExecutor:
    def __init__(self):
        self.orders_file = ORDERS_FILE
        self.execution_mode = "PAPER_TRADING_SIMULATOR"

    def execute_order(self, symbol: str, side: str, volume: int, price: float) -> Dict[str, Any]:
        # Enforce execution safety
        if volume <= 0 or price <= 0:
            return {"ok": False, "reason": "INVALID_VOLUME_OR_PRICE"}

        order_record = {
            "order_id": f"ORD-{int(time.time()*1000)}",
            "timestamp": time.time(),
            "time_iso": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
            "symbol": symbol,
            "side": side.upper(),
            "volume": volume,
            "price": price,
            "total_value": volume * price,
            "status": "FILLED",
            "mode": self.execution_mode
        }

        try:
            with open(self.orders_file, "a", encoding="utf-8") as f:
                f.write(json.dumps(order_record, ensure_ascii=False) + "\n")
            return {"ok": True, "order": order_record}
        except Exception as e:
            return {"ok": False, "reason": str(e)}

    def get_order_history(self, limit: int = 10):
        if not os.path.exists(self.orders_file):
            return []
        try:
            with open(self.orders_file, "r", encoding="utf-8") as f:
                lines = f.readlines()
            return [json.loads(l.strip()) for l in lines if l.strip()][-limit:]
        except Exception:
            return []

trade_executor = TradeExecutor()
