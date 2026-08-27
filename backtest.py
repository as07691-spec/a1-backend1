# -*- coding: utf-8 -*-
"""
A1 | Stage 13 - Basic Backtest Engine
Strategy: SMA cross (close vs moving average).
Long positions only, forced exit at end of data.
Uses Python Standard Library only (no pandas).
"""

import json
import math


def calculate_sma(values, period):
    """Simple moving average over the values list."""
    period = max(int(period), 1)
    result = [None] * len(values)
    running_sum = 0.0

    for index, value in enumerate(values):
        running_sum += value
        if index >= period:
            running_sum -= values[index - period]
        if index >= period - 1:
            result[index] = running_sum / period

    return result


def run_backtest(payload):
    """
    Executes the SMA-cross backtest.

    payload keys:
        symbol        : str
        initial_cash  : float
        sma_period    : int
        position_size : float (0 < position_size <= 1)
        data          : [{"date": str, "close": float}, ...]

    Returns:
        dict / {"error": message}
    """
    symbol = str(payload.get("symbol") or "UNKNOWN")
    initial_cash = float(payload.get("initial_cash") or 0.0)
    sma_period = max(int(payload.get("sma_period") or 20), 1)
    position_size = float(payload.get("position_size") or 1.0)
    data = payload.get("data") or []

    if len(data) < sma_period:
        return {"error": "Insufficient data for SMA period."}

    invalid = [item for item in data
               if not (isinstance(item.get("close"), (int, float)))]
    if invalid:
        return {"error": "Invalid or missing 'close' in data."}

    dates = [str(item.get("date", "")) for item in data]
    closes = [float(item["close"]) for item in data]
    sma = calculate_sma(closes, sma_period)

    cash = initial_cash
    shares = 0.0
    entry_price = 0.0
    position_open = False
    trades = []
    equity_curve = []

    def close_position(index, price, reason, timestamp):
        nonlocal cash, shares, position_open
        proceeds = shares * price
        cash += proceeds
        trades.append({
            "entry_date": entry_timestamp,
            "exit_date": timestamp,
            "entry_price": round(entry_price, 2),
            "exit_price": round(price, 2),
            "shares": round(shares, 4),
            "reason": reason,
            "pnl_toman": round(proceeds - investment, 2),
            "return_percent": round(
                (proceeds - investment) / investment * 100, 4
            ) if investment else 0.0,
        })
        shares = 0.0
        position_open = False

    entry_timestamp = None
    investment = 0.0

    for index, price in enumerate(closes):
        current_sma = sma[index]
        if (
            index == 0
            or current_sma is None
            or sma[index - 1] is None
        ):
            equity_curve.append(round(cash + shares * price, 2))
            continue

        prev_close = closes[index - 1]
        prev_sma = sma[index - 1]
        crossed_up = (
            prev_close <= prev_sma
            and price > current_sma
        )
        crossed_down = (
            prev_close >= prev_sma
            and price < current_sma
        )

        # BUY
        if not position_open and crossed_up:
            investment = cash * min(max(position_size, 0.0), 1.0)
            entry_price = price
            shares = investment / price
            entry_timestamp = dates[index]
            cash -= investment
            position_open = True

        # SELL (long only)
        elif position_open and crossed_down:
            close_position(index, price, "sma_cross_down", dates[index])

        equity_curve.append(
            round(cash + shares * price, 2)
        )

    # Forced exit at end of data
    if position_open:
        last_price = closes[-1]
        close_position(
            len(closes) - 1,
            last_price,
            "end_of_data",
            dates[-1],
        )
        if equity_curve:
            equity_curve[-1] = round(cash, 2)

    total_trades = len(trades)
    winning_trades = [t for t in trades if t["pnl_toman"] > 0]

    initial_equity = initial_cash
    final_equity = cash if not shares else cash + shares * closes[-1]

    gross_profit = sum(t["pnl_toman"] for t in trades if t["pnl_toman"] > 0)
    gross_loss = sum(t["pnl_toman"] for t in trades if t["pnl_toman"] < 0)

    peak = -math.inf
    max_drawdown = 0.0
    for value in equity_curve:
        peak = max(peak, value)
        if peak > 0:
            drawdown = (peak - value) / peak * 100
            max_drawdown = max(max_drawdown, drawdown)

    return {
        "symbol": symbol,
        "sma_period": sma_period,
        "initial_equity": round(initial_equity, 2),
        "final_equity": round(final_equity, 2),
        "net_profit": round(final_equity - initial_equity, 2),
        "total_return_percent": round(
            (final_equity - initial_equity) / initial_equity * 100, 4
        ) if initial_equity else 0.0,
        "total_trades": total_trades,
        "win_rate_percent": round(
            len(winning_trades) / total_trades * 100, 4
        ) if total_trades else 0.0,
        "gross_profit": round(gross_profit, 2),
        "gross_loss": round(gross_loss, 2),
        "profit_factor": round(
            gross_profit / abs(gross_loss), 4
        ) if gross_loss else (gross_profit if gross_profit else 0.0),
        "maximum_drawdown_percent": round(max_drawdown, 4),
        "trades": trades,
        "equity_curve": equity_curve,
    }
