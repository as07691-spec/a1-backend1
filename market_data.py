from __future__ import annotations

import os
import re
import threading
import time
from copy import deepcopy
from datetime import date
from typing import Any, Dict, List, Optional, Tuple

import httpx


class MarketDataError(ValueError):
    pass


TSETMC_DEFAULT_BASE_URL = "https://cdn.tsetmc.com"
BROWSER_USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/126.0.0.0 Safari/537.36"
)


class MarketDataService:
    def __init__(self, cache_ttl_seconds: int | None = None) -> None:
        configured_ttl = cache_ttl_seconds
        if configured_ttl is None:
            configured_ttl = int(os.getenv("A1_MARKET_CACHE_TTL", "30"))

        self.cache_ttl_seconds = max(1, configured_ttl)
        self.provider = os.getenv("A1_MARKET_DATA_PROVIDER", "mock").lower()
        self.base_url = os.getenv(
            "A1_MARKET_BASE_URL", TSETMC_DEFAULT_BASE_URL
        ).rstrip("/")
        self.timeout_seconds = float(
            os.getenv("A1_MARKET_TIMEOUT_SECONDS", "10")
        )
        self._cache: Dict[str, Tuple[float, Any]] = {}
        self._lock = threading.RLock()
        self._client: Optional[httpx.Client] = None

    @staticmethod
    def _normalize_symbol(symbol: str) -> str:
        normalized = str(symbol or "").strip().upper()

        if not normalized:
            raise MarketDataError("نماد الزامی است")

        if len(normalized) > 24:
            raise MarketDataError("طول نماد نامعتبر است")

        if not re.fullmatch(r"[A-Z0-9.\-\u0600-\u06FF]{1,24}", normalized):
            raise MarketDataError("قالب نماد نامعتبر است")

        return normalized

    def _read_cache(self, key: str) -> Any | None:
        now = time.monotonic()

        with self._lock:
            cached = self._cache.get(key)
            if cached is None:
                return None

            expires_at, value = cached
            if expires_at <= now:
                self._cache.pop(key, None)
                return None

            return deepcopy(value)

    def _write_cache(self, key: str, value: Any) -> None:
        expires_at = time.monotonic() + self.cache_ttl_seconds

        with self._lock:
            self._cache[key] = (expires_at, deepcopy(value))

    def _is_real_provider(self) -> bool:
        return self.provider in {"tsetmc", "real"}

    @staticmethod
    def _to_float(value: Any, default: float = 0.0) -> float:
        if value is None:
            return default
        try:
            return float(value)
        except (TypeError, ValueError):
            return default

    @staticmethod
    def _to_int(value: Any, default: int = 0) -> int:
        if value is None:
            return default
        try:
            return int(float(value))
        except (TypeError, ValueError):
            return default

    @staticmethod
    def _date_from_deven(deven: Any) -> str:
        try:
            raw = int(deven)
        except (TypeError, ValueError):
            return ""

        year = raw // 10000
        month = (raw // 100) % 100
        day = raw % 100

        if not (1 <= month <= 12 and 1 <= day <= 31):
            return ""

        return date(year, month, day).isoformat()

    def _get_client(self) -> httpx.Client:
        if self._client is None or self._client.is_closed:
            self._client = httpx.Client(
                base_url=self.base_url,
                timeout=self.timeout_seconds,
                follow_redirects=True,
                headers={
                    "User-Agent": BROWSER_USER_AGENT,
                    "Accept": "application/json, text/plain, */*",
                    "Accept-Language": "fa-IR,fa;q=0.9,en;q=0.8",
                    "Referer": "https://www.tsetmc.com/",
                },
            )
        return self._client

    def _request_json(self, path: str) -> Any:
        if not self._is_real_provider():
            raise MarketDataError("ارائه‌دهنده واقعی فعال نیست")

        try:
            response = self._get_client().get(path)
            response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            status_code = exc.response.status_code
            raise MarketDataError(
                f"خطای HTTP از TSETMC (کد {status_code})"
            ) from exc
        except httpx.RequestError as exc:
            raise MarketDataError(
                f"خطای شبکه در اتصال به TSETMC: {exc}"
            ) from exc

        try:
            return response.json()
        except ValueError as exc:
            raise MarketDataError("پاسخ JSON نامعتبر از TSETMC") from exc

    def _resolve_ins_code(self, symbol: str) -> str:
        normalized = self._normalize_symbol(symbol)
        cache_key = f"inscode:{normalized}"

        cached = self._read_cache(cache_key)
        if cached is not None:
            return cached

        payload = self._request_json(
            f"/api/Instrument/GetInstrumentSearch/{normalized}"
        )
        instruments = (
            payload.get("instrumentSearch") if isinstance(payload, dict) else None
        )

        if not instruments:
            raise MarketDataError(
                f"نمادی با شناسهٔ «{normalized}» در TSETMC یافت نشد"
            )

        best: Optional[str] = None
        best_score = -1
        target = normalized.upper()

        for item in instruments:
            if not isinstance(item, dict):
                continue

            ins_code = str(item.get("insCode") or "").strip()
            if not ins_code:
                continue

            ticker = str(item.get("lVal18AFC") or "").strip().upper()
            short_name = ticker
            full_name = str(item.get("lVal30") or "").strip().upper()

            score = 0
            if ticker == target:
                score = 100
            elif short_name == target:
                score = 90
            elif target in ticker or target in short_name or target in full_name:
                score = 60
            elif ticker in target or short_name in target or full_name in target:
                score = 40

            if score > best_score:
                best_score = score
                best = ins_code

        if not best:
            raise MarketDataError(
                f"نمادی با شناسهٔ «{normalized}» در TSETMC یافت نشد"
            )

        self._write_cache(cache_key, best)
        return best

    def _fetch_real_quote(self, normalized: str, ins_code: str) -> Dict[str, Any]:
        payload = self._request_json(
            f"/api/ClosingPrice/GetClosingPriceInfo/{ins_code}"
        )
        info = payload.get("closingPriceInfo") if isinstance(payload, dict) else None

        if not info:
            raise MarketDataError("دادهٔ قیمت پایانی برای نماد یافت نشد")

        last_price = self._to_float(info.get("pDrCotVal")) or self._to_float(
            info.get("pl")
        )
        yesterday = self._to_float(info.get("priceYesterday")) or self._to_float(
            info.get("py")
        )
        change_percent = 0.0
        if yesterday:
            change_percent = round(((last_price - yesterday) / yesterday) * 100.0, 2)
        volume = self._to_int(info.get("qTotTran5J")) or self._to_int(info.get("qtc"))
        trade_value = self._to_float(info.get("qTotCap"))
        trade_count = self._to_int(info.get("zTotTran"))

        quote: Dict[str, Any] = {
            "symbol": normalized,
            "ins_code": ins_code,
            "last_price": last_price,
            "last_trade_price": self._to_float(info.get("pClosing")),
            "yesterday_price": yesterday,
            "change_percent": change_percent,
            "volume": volume,
            "trade_value": trade_value,
            "trade_count": trade_count,
            "timestamp": time.time(),
            "provider": self.provider,
            "cache_hit": False,
            "cache_ttl_seconds": self.cache_ttl_seconds,
        }

        try:
            ct_payload = self._request_json(
                f"/api/ClientType/GetClientType/{ins_code}/1/0"
            )
            ct = (
                ct_payload.get("clientType")
                if isinstance(ct_payload, dict)
                else None
            )
            if ct:
                quote["real_buy_volume"] = self._to_int(ct.get("buy_I_Volume"))
                quote["real_sell_volume"] = self._to_int(ct.get("sell_I_Volume"))
                quote["legal_buy_volume"] = self._to_int(ct.get("buy_N_Volume"))
                quote["legal_sell_volume"] = self._to_int(ct.get("sell_N_Volume"))
                quote["buyer_count"] = self._to_int(
                    ct.get("buy_CountI") or ct.get("CountI")
                )
                quote["seller_count"] = self._to_int(
                    ct.get("sell_CountI") or ct.get("CountI")
                )
        except MarketDataError:
            pass

        return quote

    def _fetch_real_history(
        self, normalized: str, ins_code: str, timeframe: str
    ) -> Dict[str, Any]:
        top = 60 if timeframe == "daily" else 180

        payload = self._request_json(
            f"/api/ClosingPrice/GetClosingPriceDailyList/{ins_code}/{top}"
        )
        rows = payload.get("closingPriceDaily") if isinstance(payload, dict) else None

        if not rows:
            raise MarketDataError("دادهٔ تاریخی نماد یافت نشد")

        if timeframe == "weekly":
            rows = rows[::5]

        records: List[Dict[str, Any]] = []
        for row in rows:
            close = self._to_float(row.get("pClosing")) or self._to_float(
                row.get("pc")
            )
            records.append(
                {
                    "date": self._date_from_deven(row.get("dEven")),
                    "open": self._to_float(row.get("priceFirst"))
                    or self._to_float(row.get("pf")),
                    "high": self._to_float(row.get("priceMax")),
                    "low": self._to_float(row.get("priceMin")),
                    "close": close,
                    "volume": self._to_int(row.get("qTotTran5J"))
                    or self._to_int(row.get("qtc")),
                }
            )

        return {
            "symbol": normalized,
            "ins_code": ins_code,
            "timeframe": timeframe,
            "provider": self.provider,
            "cache_hit": False,
            "cache_ttl_seconds": self.cache_ttl_seconds,
            "count": len(records),
            "data": records,
        }

    def get_latest_quote(self, symbol: str) -> Dict[str, Any]:
        normalized = self._normalize_symbol(symbol)
        cache_key = f"quote:{normalized}"

        cached = self._read_cache(cache_key)
        if cached is not None:
            cached["cache_hit"] = True
            return cached

        if self._is_real_provider():
            ins_code = self._resolve_ins_code(normalized)
            quote = self._fetch_real_quote(normalized, ins_code)
        else:
            quote = {
                "symbol": normalized,
                "last_price": 1000.0,
                "change_percent": 1.5,
                "volume": 500000,
                "timestamp": time.time(),
                "provider": self.provider,
                "cache_hit": False,
                "cache_ttl_seconds": self.cache_ttl_seconds,
            }

        self._write_cache(cache_key, quote)
        return quote

    def get_historical_data(
        self,
        symbol: str,
        timeframe: str = "daily",
    ) -> Dict[str, Any]:
        normalized = self._normalize_symbol(symbol)
        normalized_timeframe = str(timeframe or "daily").strip().lower()

        if normalized_timeframe not in {"daily", "weekly"}:
            raise MarketDataError("بازه زمانی باید daily یا weekly باشد")

        cache_key = f"history:{normalized}:{normalized_timeframe}"

        cached = self._read_cache(cache_key)
        if cached is not None:
            cached["cache_hit"] = True
            return cached

        if self._is_real_provider():
            ins_code = self._resolve_ins_code(normalized)
            result = self._fetch_real_history(
                normalized, ins_code, normalized_timeframe
            )
        else:
            closes = [
                960.0, 970.0, 980.0, 995.0, 1010.0, 1000.0,
                985.0, 995.0, 1015.0, 1000.0,
            ]
            records: List[Dict[str, Any]] = []

            for index, close in enumerate(closes, start=1):
                records.append(
                    {
                        "date": f"2026-08-{index + 5:02d}",
                        "open": close - 5.0,
                        "high": close + 10.0,
                        "low": close - 10.0,
                        "close": close,
                        "volume": 350000 + (index * 15000),
                    }
                )

            result = {
                "symbol": normalized,
                "timeframe": normalized_timeframe,
                "provider": self.provider,
                "cache_hit": False,
                "cache_ttl_seconds": self.cache_ttl_seconds,
                "count": len(records),
                "data": records,
            }

        self._write_cache(cache_key, result)
        return result

    def clear_cache(self) -> Dict[str, Any]:
        with self._lock:
            cleared_items = len(self._cache)
            self._cache.clear()

        return {
            "status": "ok",
            "cleared_items": cleared_items,
            "message": "کش داده‌های بازار پاک شد",
        }

    def status(self) -> Dict[str, Any]:
        with self._lock:
            cache_items = len(self._cache)

        return {
            "status": "operational",
            "provider": self.provider,
            "mode": "mock" if self.provider == "mock" else "configured",
            "cache_ttl_seconds": self.cache_ttl_seconds,
            "cache_items": cache_items,
            "external_network_required": self.provider != "mock",
            "base_url": self.base_url,
            "timeout_seconds": self.timeout_seconds,
        }
