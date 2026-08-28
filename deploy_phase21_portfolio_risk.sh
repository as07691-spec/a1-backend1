#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: deploy_phase21_portfolio_risk.sh
# PURPOSE: Deploy Phase 21 Portfolio & Risk Engine into A1 Studio Backend
# TARGET DIRECTORY: /opt/a1/backend
# ARCHITECTURE ROLE: GapGPT (Architecture, QA & Contracts)
# ==============================================================================

set -euo pipefail

BACKEND_DIR="/opt/a1/backend"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="${BACKEND_DIR}/backups/backup_phase21_${TIMESTAMP}"

echo ">>> [STAGE 1] Creating Stage 21 System Backup..."
mkdir -p "${BACKUP_DIR}"
if [ -f "${BACKEND_DIR}/app/main.py" ]; then
    cp "${BACKEND_DIR}/app/main.py" "${BACKUP_DIR}/main.py.bak"
fi
if [ -f "${BACKEND_DIR}/app/portfolio.py" ]; then
    cp "${BACKEND_DIR}/app/portfolio.py" "${BACKUP_DIR}/portfolio.py.bak"
fi
if [ -f "${BACKEND_DIR}/app/risk.py" ]; then
    cp "${BACKEND_DIR}/app/risk.py" "${BACKUP_DIR}/risk.py.bak"
fi
echo "Backup saved to: ${BACKUP_DIR}"

echo ">>> [STAGE 2] Deploying Portfolio Module (/opt/a1/backend/app/portfolio.py)..."
cat << 'PY_EOF' > "${BACKEND_DIR}/app/portfolio.py"
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
PY_EOF

echo ">>> [STAGE 3] Deploying Risk Assessment Module (/opt/a1/backend/app/risk.py)..."
cat << 'PY_EOF' > "${BACKEND_DIR}/app/risk.py"
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
PY_EOF

echo ">>> [STAGE 4] Injecting Portfolio & Risk Endpoints into main.py..."
python3 - << 'PY_EOF'
main_path = "/opt/a1/backend/app/main.py"
with open(main_path, "r", encoding="utf-8") as f:
    content = f.read()

portfolio_risk_routes = """
# =====================================================================
# Phase 21: Portfolio & Risk Engine Endpoints
# =====================================================================
try:
    from app.portfolio import portfolio_engine, Position, PortfolioSummary
    from app.risk import risk_engine, RiskCheckRequest, RiskCheckResult
except ImportError:
    from portfolio import portfolio_engine, Position, PortfolioSummary
    from risk import risk_engine, RiskCheckRequest, RiskCheckResult

@app.get("/api/v1/portfolio/summary", response_model=PortfolioSummary, tags=["Portfolio"])
async def get_portfolio_summary():
    return portfolio_engine.get_summary()

@app.get("/api/v1/portfolio/positions", tags=["Portfolio"])
async def get_portfolio_positions():
    return {"positions": portfolio_engine.get_positions()}

@app.post("/api/v1/risk/check-order", response_model=RiskCheckResult, tags=["Risk"])
async def check_order_risk(order: RiskCheckRequest):
    summary = portfolio_engine.get_summary()
    return risk_engine.evaluate_order(
        symbol=order.symbol,
        side=order.side,
        quantity=order.quantity,
        price=order.price,
        total_portfolio_value=summary.total_value
    )
"""

if "/api/v1/portfolio/summary" not in content:
    content += "\n" + portfolio_risk_routes
    with open(main_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("[INFO] Portfolio & Risk routes successfully injected into main.py")
else:
    print("[INFO] Portfolio & Risk routes already present in main.py")
PY_EOF

echo ">>> [STAGE 5] Validating Python Syntax..."
python3 -m py_compile /opt/a1/backend/app/portfolio.py
python3 -m py_compile /opt/a1/backend/app/risk.py
python3 -m py_compile /opt/a1/backend/app/main.py

echo ">>> [STAGE 6] Restarting a1-agent Service..."
systemctl restart a1-agent.service
sleep 2

echo ">>> [STAGE 7] Executing Verification & Smoke Tests..."
systemctl is-active --quiet a1-agent.service && echo "Service status: active (running)" || { echo "Service failed!"; exit 1; }

echo "Testing Portfolio Summary Endpoint..."
SUMMARY_RES=$(curl -s -w "\n%{http_code}" http://127.0.0.1:8000/api/v1/portfolio/summary)
SUMMARY_CODE=$(echo "$SUMMARY_RES" | tail -n1)
SUMMARY_BODY=$(echo "$SUMMARY_RES" | head -n -1)

if [ "$SUMMARY_CODE" -eq 200 ]; then
    echo "Portfolio Summary OK: $SUMMARY_BODY"
else
    echo "Portfolio Summary Failed with code $SUMMARY_CODE"
    exit 1
fi

echo "Testing Risk Check Endpoint..."
RISK_RES=$(curl -s -w "\n%{http_code}" -X POST http://127.0.0.1:8000/api/v1/risk/check-order \
  -H "Content-Type: application/json" \
  -d '{"symbol": "فولاد", "side": "BUY", "quantity": 1000, "price": 5000}')
RISK_CODE=$(echo "$RISK_RES" | tail -n1)
RISK_BODY=$(echo "$RISK_RES" | head -n -1)

if [ "$RISK_CODE" -eq 200 ]; then
    echo "Risk Check OK: $RISK_BODY"
else
    echo "Risk Check Failed with code $RISK_CODE"
    exit 1
fi

echo "=============================================================================="
echo " PHASE 21 COMPLETE: Portfolio & Risk engines deployed and verified."
echo "=============================================================================="
