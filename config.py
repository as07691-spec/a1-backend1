"""A1 — پیکربندی مرکزی از متغیرهای محیطی.

این نسخه عمداً به pydantic-settings وابسته نیست تا
در محیط‌های ایزوله و بدون اینترنت نیز اجرا شود.
"""

import os
from pathlib import Path


def _load_dotenv(path: Path) -> None:
    """بارگذاری ساده و سازگار فایل .env."""
    if not path.is_file():
        return

    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return

    for raw_line in lines:
        line = raw_line.strip()

        if not line or line.startswith("#"):
            continue

        if line.startswith("export "):
            line = line[7:].strip()

        if "=" not in line:
            continue

        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()

        if not key:
            continue

        if len(value) >= 2:
            if value[0] == value[-1] and value[0] in ("'", '"'):
                value = value[1:-1]

        # متغیرهای واقعی محیطی بر مقدار .env اولویت دارند.
        os.environ.setdefault(key, value)


_load_dotenv(Path(__file__).resolve().parent / ".env")


def _as_bool(value: str | None, default: bool = False) -> bool:
    if value is None:
        return default

    return value.strip().lower() in {
        "1",
        "true",
        "yes",
        "y",
        "on",
        "فعال",
        "بله",
    }


class Settings:
    """تنظیمات مورد استفاده توسط main.py و سایر بخش‌های بک‌اند."""

    def __init__(self) -> None:
        self.app_name = os.getenv("APP_NAME", "A1 Agent")
        self.version = os.getenv("VERSION", "0.16.0")
        self.debug = _as_bool(os.getenv("DEBUG"), False)
        self.api_prefix = os.getenv("API_PREFIX", "/api/v1")
        self.market_base = os.getenv(
            "MARKET_BASE",
            "https://www.tsetmc.com",
        )


settings = Settings()
