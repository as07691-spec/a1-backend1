"""A1 smart-money analysis - Stage 7 (standard library only).

Honest, professional technical signals from OHLCV rows only.

Signals
-------
1. Unusual volume
   A day is flagged when its volume exceeds the average of the PRIOR
   `window` sessions multiplied by `volume_threshold`. The current day is
   excluded from its own average to avoid self-inflation bias.

2. Transaction value (billions of rials)
   transaction_value_billion = close * volume / 1_000_000_000

3. Money flow (accumulation vs distribution)
   typical_price = (high + low + close) / 3
   raw_money_flow = typical_price * volume
   Positive flow when typical price rises; negative when it falls.
   money_flow_ratio = positive / (positive + negative)

Honesty note
------------
The current market-data provider returns only OHLCV. It does NOT expose
real buy/sell volume or buyer/seller counts, so a true per-capita buyer
power cannot be computed and is never reported as such. The endpoint
instead reports the honest signals above.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional


class SmartMoneyDetector:
    """Detect smart-money signals from OHLCV market rows."""

    def __init__(self, volume_threshold: float = 2.0) -> None:
        if volume_threshold <= 0:
            raise ValueError("volume_threshold must be greater than zero")
        self.volume_threshold = float(volume_threshold)

    @staticmethod
    def _copy(row: Dict[str, Any]) -> Dict[str, Any]:
        return dict(row)

    def detect_unusual_volume(
        self,
        rows: List[Dict[str, Any]],
        window: int = 22,
    ) -> List[Dict[str, Any]]:
        """Flag volume spikes against the prior-window average."""
        if window <= 0:
            raise ValueError("window must be a positive integer")

        output: List[Dict[str, Any]] = []
        for index, row in enumerate(rows):
            item = self._copy(row)
            prior = rows[max(0, index - window):index]
            if prior:
                avg_volume = sum(float(r["volume"]) for r in prior) / len(prior)
            else:
                avg_volume = float(row["volume"])

            item["avg_volume"] = round(avg_volume, 4)
            item["is_unusual_volume"] = (
                float(row["volume"]) > (avg_volume * self.volume_threshold)
            )
            output.append(item)
        return output

    def detect_transaction_value(
        self,
        rows: List[Dict[str, Any]],
    ) -> List[Dict[str, Any]]:
        """Append the normalized transaction value in billions of rials."""
        output: List[Dict[str, Any]] = []
        for row in rows:
            item = self._copy(row)
            close = float(row["close"])
            volume = float(row["volume"])
            item["transaction_value_billion"] = round(
                (close * volume) / 1_000_000_000, 4
            )
            output.append(item)
        return output

    def detect_money_flow(
        self,
        rows: List[Dict[str, Any]],
    ) -> List[Dict[str, Any]]:
        """Append money-flow fields used for accumulation/distribution."""
        output: List[Dict[str, Any]] = []
        previous_tp: Optional[float] = None

        for row in rows:
            item = self._copy(row)
            high = float(row["high"])
            low = float(row["low"])
            close = float(row["close"])
            volume = float(row["volume"])

            typical_price = (high + low + close) / 3.0
            raw_money_flow = typical_price * volume

            item["typical_price"] = round(typical_price, 4)
            item["raw_money_flow"] = round(raw_money_flow, 4)

            if previous_tp is None:
                item["money_flow_positive"] = 0.0
                item["money_flow_negative"] = 0.0
            elif typical_price > previous_tp:
                item["money_flow_positive"] = round(raw_money_flow, 4)
                item["money_flow_negative"] = 0.0
            elif typical_price < previous_tp:
                item["money_flow_positive"] = 0.0
                item["money_flow_negative"] = round(raw_money_flow, 4)
            else:
                item["money_flow_positive"] = 0.0
                item["money_flow_negative"] = 0.0

            previous_tp = typical_price
            output.append(item)
        return output

    def money_flow_ratio(
        self,
        rows: List[Dict[str, Any]],
    ) -> float:
        """Return positive flow share over the full series, 0..1."""
        positive = sum(float(r.get("money_flow_positive", 0.0)) for r in rows)
        negative = sum(float(r.get("money_flow_negative", 0.0)) for r in rows)
        total = positive + negative
        if total <= 0:
            return 0.5
        return round(positive / total, 4)

    def smart_money_alert(
        self,
        rows: List[Dict[str, Any]],
    ) -> bool:
        """Combined alert: strong positive flow plus unusual-volume up day."""
        if not rows:
            return False
        ratio = self.money_flow_ratio(rows)
        last = rows[-1]
        up_day = float(last.get("close", 0.0)) > float(last.get("open", 0.0))
        unusual = bool(last.get("is_unusual_volume", False))
        return bool(ratio >= 0.6 and unusual and up_day)
