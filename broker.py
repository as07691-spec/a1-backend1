from __future__ import annotations

import json
import os
import re
import threading
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


class BrokerError(Exception):
    def __init__(self, message: str, status_code: int = 400):
        super().__init__(message)
        self.message = message
        self.status_code = status_code


class PaperBroker:
    VALID_SIDES = {"buy", "sell"}
    VALID_ORDER_TYPES = {"market"}
    SYMBOL_PATTERN = re.compile(r"^[A-Z0-9._-]{1,32}$")
    CLIENT_ID_PATTERN = re.compile(r"^[A-Za-z0-9._:-]{1,64}$")

    def __init__(
        self,
        state_path: str | Path = "data/paper_broker_state.json",
        events_path: str | Path = "data/broker_events.jsonl",
    ):
        self.requested_mode = os.getenv("A1_BROKER_MODE", "paper").strip().lower()
        self.mode = "paper"
        self.enabled = self.requested_mode == "paper"
        self.state_path = Path(state_path)
        self.events_path = Path(events_path)
        self.lock = threading.RLock()

        try:
            initial_cash = float(os.getenv("A1_PAPER_INITIAL_CASH", "1000000000"))
        except ValueError as exc:
            raise RuntimeError("A1_PAPER_INITIAL_CASH must be numeric") from exc

        if initial_cash <= 0:
            raise RuntimeError("A1_PAPER_INITIAL_CASH must be positive")

        self.state_path.parent.mkdir(parents=True, exist_ok=True)
        self.events_path.parent.mkdir(parents=True, exist_ok=True)
        self.state = self._load_state(initial_cash)

        if not self.enabled:
            self._record_event(
                "broker_disabled",
                {
                    "requested_mode": self.requested_mode,
                    "reason": "Only paper mode is implemented",
                },
            )

    @staticmethod
    def _utc_now() -> str:
        return datetime.now(timezone.utc).isoformat()

    def _default_state(self, initial_cash: float) -> dict[str, Any]:
        return {
            "schema_version": 1,
            "initial_cash": round(initial_cash, 4),
            "cash": round(initial_cash, 4),
            "realized_pnl": 0.0,
            "orders": [],
            "positions": {},
            "updated_at": self._utc_now(),
        }

    def _load_state(self, initial_cash: float) -> dict[str, Any]:
        if not self.state_path.exists():
            state = self._default_state(initial_cash)
            self._save_state_value(state)
            return state

        try:
            state = json.loads(self.state_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise RuntimeError(f"Cannot read broker state: {exc}") from exc

        required = {"initial_cash", "cash", "realized_pnl", "orders", "positions"}
        if not isinstance(state, dict) or not required.issubset(state):
            raise RuntimeError("Broker state file has an invalid structure")

        return state

    def _save_state_value(self, state: dict[str, Any]) -> None:
        state["updated_at"] = self._utc_now()
        temporary = self.state_path.with_suffix(".tmp")
        temporary.write_text(
            json.dumps(state, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        os.replace(temporary, self.state_path)

    def _save_state(self) -> None:
        self._save_state_value(self.state)

    def _record_event(self, event_type: str, data: dict[str, Any]) -> None:
        event = {
            "event_id": str(uuid.uuid4()),
            "event_type": event_type,
            "broker_mode": self.mode,
            "created_at": self._utc_now(),
            "data": data,
        }
        with self.events_path.open("a", encoding="utf-8") as stream:
            stream.write(json.dumps(event, ensure_ascii=False) + "\n")

    def _ensure_enabled(self) -> None:
        if not self.enabled:
            raise BrokerError(
                "Broker is disabled because only A1_BROKER_MODE=paper is allowed",
                503,
            )

    def status(self) -> dict[str, Any]:
        return {
            "mode": self.mode,
            "requested_mode": self.requested_mode,
            "enabled": self.enabled,
            "live_trading_supported": False,
            "state_persistence": str(self.state_path),
            "event_log": str(self.events_path),
        }

    def submit_order(self, payload: dict[str, Any]) -> dict[str, Any]:
        self._ensure_enabled()

        if not isinstance(payload, dict):
            raise BrokerError("Order payload must be an object", 422)

        symbol = str(payload.get("symbol", "")).strip().upper()
        side = str(payload.get("side", "")).strip().lower()
        order_type = str(payload.get("order_type", "market")).strip().lower()
        client_order_id = str(payload.get("client_order_id", "")).strip()

        if not self.SYMBOL_PATTERN.fullmatch(symbol):
            raise BrokerError("symbol is invalid", 422)
        if side not in self.VALID_SIDES:
            raise BrokerError("side must be buy or sell", 422)
        if order_type not in self.VALID_ORDER_TYPES:
            raise BrokerError("Only market orders are supported", 422)
        if not self.CLIENT_ID_PATTERN.fullmatch(client_order_id):
            raise BrokerError("client_order_id is invalid", 422)

        quantity_value = payload.get("quantity")
        if isinstance(quantity_value, bool):
            raise BrokerError("quantity must be a positive integer", 422)

        try:
            quantity = int(quantity_value)
        except (TypeError, ValueError) as exc:
            raise BrokerError("quantity must be a positive integer", 422) from exc

        if quantity <= 0 or quantity != quantity_value:
            raise BrokerError("quantity must be a positive integer", 422)

        price_value = payload.get("market_price")
        try:
            market_price = float(price_value)
        except (TypeError, ValueError) as exc:
            raise BrokerError(
                "market_price is required for paper market orders",
                422,
            ) from exc

        if market_price <= 0:
            raise BrokerError("market_price must be positive", 422)

        market_price = round(market_price, 4)

        with self.lock:
            for existing in self.state["orders"]:
                if existing["client_order_id"] == client_order_id:
                    return {
                        **existing,
                        "idempotent_replay": True,
                    }

            position = self.state["positions"].get(
                symbol,
                {
                    "symbol": symbol,
                    "quantity": 0,
                    "average_price": 0.0,
                    "last_price": market_price,
                },
            )

            current_quantity = int(position["quantity"])
            current_average = float(position["average_price"])
            gross_amount = round(quantity * market_price, 4)

            if side == "buy":
                if gross_amount > float(self.state["cash"]):
                    raise BrokerError("Insufficient paper cash", 409)

                new_quantity = current_quantity + quantity
                new_average = (
                    (current_quantity * current_average) + gross_amount
                ) / new_quantity

                self.state["cash"] = round(
                    float(self.state["cash"]) - gross_amount,
                    4,
                )
                position.update(
                    {
                        "quantity": new_quantity,
                        "average_price": round(new_average, 4),
                        "last_price": market_price,
                    }
                )
                self.state["positions"][symbol] = position
                realized_pnl = 0.0
            else:
                if quantity > current_quantity:
                    raise BrokerError("Insufficient position quantity", 409)

                realized_pnl = round(
                    (market_price - current_average) * quantity,
                    4,
                )
                remaining_quantity = current_quantity - quantity
                self.state["cash"] = round(
                    float(self.state["cash"]) + gross_amount,
                    4,
                )
                self.state["realized_pnl"] = round(
                    float(self.state["realized_pnl"]) + realized_pnl,
                    4,
                )

                if remaining_quantity == 0:
                    self.state["positions"].pop(symbol, None)
                else:
                    position.update(
                        {
                            "quantity": remaining_quantity,
                            "last_price": market_price,
                        }
                    )
                    self.state["positions"][symbol] = position

            created_at = self._utc_now()
            order = {
                "order_id": str(uuid.uuid4()),
                "client_order_id": client_order_id,
                "symbol": symbol,
                "side": side,
                "quantity": quantity,
                "order_type": order_type,
                "status": "filled",
                "filled_quantity": quantity,
                "average_fill_price": market_price,
                "gross_amount": gross_amount,
                "realized_pnl": realized_pnl,
                "broker_mode": self.mode,
                "created_at": created_at,
                "updated_at": created_at,
                "idempotent_replay": False,
            }

            self.state["orders"].append(order)
            self._save_state()
            self._record_event("order_filled", order)
            return order

    def get_order(self, order_id: str) -> dict[str, Any]:
        with self.lock:
            for order in self.state["orders"]:
                if order["order_id"] == order_id:
                    return dict(order)
        raise BrokerError("Order not found", 404)

    def list_orders(self, limit: int = 100) -> list[dict[str, Any]]:
        if limit < 1 or limit > 500:
            raise BrokerError("limit must be between 1 and 500", 422)
        with self.lock:
            return [
                dict(order)
                for order in reversed(self.state["orders"][-limit:])
            ]

    def list_positions(self) -> list[dict[str, Any]]:
        with self.lock:
            result = []
            for position in self.state["positions"].values():
                quantity = int(position["quantity"])
                average_price = float(position["average_price"])
                last_price = float(position["last_price"])
                result.append(
                    {
                        **position,
                        "market_value": round(quantity * last_price, 4),
                        "unrealized_pnl": round(
                            quantity * (last_price - average_price),
                            4,
                        ),
                    }
                )
            return sorted(result, key=lambda item: item["symbol"])

    def account(self) -> dict[str, Any]:
        positions = self.list_positions()
        market_value = round(
            sum(float(item["market_value"]) for item in positions),
            4,
        )
        unrealized_pnl = round(
            sum(float(item["unrealized_pnl"]) for item in positions),
            4,
        )
        cash = round(float(self.state["cash"]), 4)
        equity = round(cash + market_value, 4)

        return {
            "broker_mode": self.mode,
            "currency": "IRR",
            "initial_cash": self.state["initial_cash"],
            "cash": cash,
            "market_value": market_value,
            "equity": equity,
            "realized_pnl": round(float(self.state["realized_pnl"]), 4),
            "unrealized_pnl": unrealized_pnl,
            "total_pnl": round(
                equity - float(self.state["initial_cash"]),
                4,
            ),
            "open_positions": len(positions),
        }

    def list_events(self, limit: int = 100) -> list[dict[str, Any]]:
        if limit < 1 or limit > 500:
            raise BrokerError("limit must be between 1 and 500", 422)
        if not self.events_path.exists():
            return []

        lines = self.events_path.read_text(encoding="utf-8").splitlines()
        events = []
        for line in lines[-limit:]:
            if line.strip():
                events.append(json.loads(line))
        return list(reversed(events))
