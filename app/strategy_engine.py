# Purpose: Maintain in-memory strategy signals and history.
# Logic: Provides FIFO ring buffer for local strategy analysis.

import time
from typing import List, Dict, Any

class StrategyManager:
    def __init__(self):
        self.active_strategy = "MOMENTUM_LOCAL_V1"
        self._history: List[Dict[str, Any]] = []

    def record_signal(self, signal_data: Dict[str, Any]):
        entry = {
            "timestamp": time.time(),
            "data": signal_data
        }
        self._history.insert(0, entry)
        if len(self._history) > 50:
            self._history.pop()

    def get_recent_signals(self, limit: int = 5) -> List[Dict[str, Any]]:
        return self._history[:limit]

strategy_mgr = StrategyManager()
