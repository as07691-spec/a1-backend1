import uuid
from datetime import datetime
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field

class OrderRequest(BaseModel):
    symbol: str = Field(..., description="Instrument symbol (e.g. فولاد, خودرو)")
    side: str = Field(..., description="Order side: 'BUY' or 'SELL'")
    quantity: int = Field(..., gt=0, description="Order volume in shares")
    price: float = Field(..., gt=0, description="Order limit price in Rials")
    order_type: str = Field("LIMIT", description="Order type: LIMIT or MARKET")

class TradeEngine:
    def __init__(self):
        self.orders: Dict[str, Dict[str, Any]] = {}

    def place_order(self, order: OrderRequest) -> Dict[str, Any]:
        order_id = str(uuid.uuid4())[:8]
        timestamp = datetime.now().isoformat()
        side = order.side.upper()
        if side not in ["BUY", "SELL"]:
            return {"success": False, "error": f"Invalid side: {order.side}"}

        record = {
            "order_id": order_id,
            "symbol": order.symbol,
            "side": side,
            "quantity": order.quantity,
            "price": order.price,
            "order_type": order.order_type.upper(),
            "status": "FILLED",
            "filled_quantity": order.quantity,
            "average_price": order.price,
            "total_value": order.quantity * order.price,
            "timestamp": timestamp,
            "error_message": None
        }
        self.orders[order_id] = record
        return {"success": True, "order": record}

    def get_order(self, order_id: str) -> Optional[Dict[str, Any]]:
        return self.orders.get(order_id)

    def list_orders(self, symbol: Optional[str] = None) -> List[Dict[str, Any]]:
        order_list = list(self.orders.values())
        if symbol:
            order_list = [o for o in order_list if o["symbol"] == symbol]
        return sorted(order_list, key=lambda x: x["timestamp"], reverse=True)

trade_engine = TradeEngine()
