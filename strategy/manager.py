import os
import json
import time
from typing import Dict, Any, List

HISTORY_FILE = "/opt/a1/backend/data/trade_signals.jsonl"

class StrategyManager:
    def __init__(self):
        self.active_strategy = "Adaptive-Mean-Reversion-v1"
        self.history_file = HISTORY_FILE

    def record_signal(self, signal_data: Dict[str, Any]) -> None:
        try:
            entry = {
                "timestamp": time.time(),
                "time_iso": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
                "signal": signal_data.get("signal", "HOLD"),
                "risk_score": signal_data.get("risk_score", 0.0),
                "model": signal_data.get("model", "local"),
                "power_ratio": signal_data.get("metrics", {}).get("power_ratio", 0.0)
            }
            with open(self.history_file, "a", encoding="utf-8") as f:
                f.write(json.dumps(entry, ensure_ascii=False) + "\n")
        except Exception:
            pass

    def get_recent_signals(self, limit: int = 10) -> List[Dict[str, Any]]:
        if not os.path.exists(self.history_file):
            return []
        try:
            with open(self.history_file, "r", encoding="utf-8") as f:
                lines = f.readlines()
            records = [json.loads(line.strip()) for line in lines if line.strip()]
            return records[-limit:]
        except Exception:
            return []

strategy_mgr = StrategyManager()
