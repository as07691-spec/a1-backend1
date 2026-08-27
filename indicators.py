"""A1 technical indicators.

This module uses only Python standard library.
It must not block API startup when pandas or numpy is not installed.
"""

from __future__ import annotations


class TechnicalAnalysis:
    """Small technical-analysis helper for boot-safe API tests."""

    @staticmethod
    def calculate_sma(data: list[float], period: int) -> list[float | None]:
        if period <= 0:
            raise ValueError("period must be greater than zero")

        result: list[float | None] = []
        for index in range(len(data)):
            if index + 1 < period:
                result.append(None)
                continue

            window = data[index + 1 - period:index + 1]
            result.append(sum(window) / period)

        return result

    @staticmethod
    def calculate_rsi(data: list[float], period: int = 14) -> list[float | None]:
        if period <= 0:
            raise ValueError("period must be greater than zero")

        if len(data) < 2:
            return [None for _ in data]

        changes = [0.0]
        for index in range(1, len(data)):
            changes.append(float(data[index]) - float(data[index - 1]))

        result: list[float | None] = []
        for index in range(len(data)):
            if index + 1 < period + 1:
                result.append(None)
                continue

            window = changes[index + 1 - period:index + 1]
            gains = [value for value in window if value > 0]
            losses = [-value for value in window if value < 0]

            avg_gain = sum(gains) / period
            avg_loss = sum(losses) / period

            if avg_loss == 0:
                result.append(100.0)
                continue

            rs = avg_gain / avg_loss
            result.append(100.0 - (100.0 / (1.0 + rs)))

        return result

    @staticmethod
    def calculate_bollinger_bands(
        data: list[float],
        period: int = 20,
        std_dev: float = 2.0,
    ) -> tuple[list[float | None], list[float | None]]:
        if period <= 0:
            raise ValueError("period must be greater than zero")

        upper: list[float | None] = []
        lower: list[float | None] = []

        for index in range(len(data)):
            if index + 1 < period:
                upper.append(None)
                lower.append(None)
                continue

            window = [float(x) for x in data[index + 1 - period:index + 1]]
            mean = sum(window) / period
            variance = sum((x - mean) ** 2 for x in window) / period
            std = variance ** 0.5

            upper.append(mean + std * std_dev)
            lower.append(mean - std * std_dev)

        return upper, lower
