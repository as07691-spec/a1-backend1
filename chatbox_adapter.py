import json
import logging
import os
import time
import uuid
from collections.abc import AsyncIterator
from typing import Any

import httpx
from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, ConfigDict, Field

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)

logger = logging.getLogger("a1-llm-router")

app = FastAPI(
    title="A1 LLM Router",
    version="1.1.0",
)

DAHL_BASE_URL = os.getenv(
    "DAHL_BASE_URL",
    "https://inference.dahl.global/v1",
).rstrip("/")

DAHL_API_KEY = os.getenv("DAHL_API_KEY", "").strip()
HCNSEC_BASE_URL = os.getenv(
    "HCNSEC_BASE_URL", "https://api.hcnsec.cn/v1"
).rstrip("/")
HCNSEC_API_KEY = os.getenv("HCNSEC_API_KEY", "").strip()
HCNSEC_MODEL = os.getenv("HCNSEC_MODEL", "deepseek-chat-v3.1").strip()
CHATBOX_TOKEN = os.getenv("A1_CHATBOX_TOKEN", "").strip()

try:
    DAHL_TIMEOUT = float(os.getenv("DAHL_TIMEOUT", "120"))
except ValueError:
    DAHL_TIMEOUT = 120.0


MODELS = {
    "coding": "deepseek-ai/DeepSeek-V4-Flash-0731",
    "analysis": "moonshotai/Kimi-K2.6",
    "general": "MiniMaxAI/MiniMax-M2.7",
}

ALL_MODELS = set(MODELS.values())
ALL_MODELS.add(HCNSEC_MODEL)


class Message(BaseModel):
    model_config = ConfigDict(extra="allow")

    role: str
    content: Any


class ChatCompletionRequest(BaseModel):
    model_config = ConfigDict(extra="allow")

    model: str = Field(default="auto")
    messages: list[Message] = Field(min_length=1)
    stream: bool = False
    temperature: float | None = None
    max_tokens: int | None = None
    top_p: float | None = None


def content_to_text(content: Any) -> str:
    if isinstance(content, str):
        return content

    if isinstance(content, list):
        parts: list[str] = []
        for item in content:
            if isinstance(item, dict) and item.get("type") == "text":
                parts.append(str(item.get("text", "")))
        return "\n".join(parts)

    return str(content)


def latest_user_text(messages: list[Message]) -> str:
    for message in reversed(messages):
        if message.role == "user":
            return content_to_text(message.content)
    return content_to_text(messages[-1].content)


def route_model(text: str) -> str:
    value = text.lower()

    coding_terms = (
        "python",
        "bash",
        "shell",
        "terminal",
        "ubuntu",
        "linux",
        "systemd",
        "api",
        "fastapi",
        "uvicorn",
        "code",
        "coding",
        "script",
        "کد",
        "پایتون",
        "ترمینال",
        "اوبونتو",
        "لینوکس",
        "سرویس",
        "اسکریپت",
        "برنامه",
    )

    analysis_terms = (
        "analyze",
        "analysis",
        "compare",
        "research",
        "why",
        "strategy",
        "data",
        "report",
        "تحلیل",
        "مقایسه",
        "بررسی",
        "دلیل",
        "استراتژی",
        "داده",
        "گزارش",
    )

    if any(term in value for term in coding_terms):
        return MODELS["coding"]

    if any(term in value for term in analysis_terms):
        return MODELS["analysis"]

    return MODELS["general"]


def model_sequence(selected: str, text: str) -> list[str]:
    first = HCNSEC_MODEL if selected in ("", "auto") else selected

    if first not in ALL_MODELS:
        raise HTTPException(
            status_code=400,
            detail={
                "error": "unsupported_model",
            "allowed_models": ["auto", *sorted(ALL_MODELS)],
            },
        )

    ordered = [
        first,
        MODELS["general"],
        MODELS["analysis"],
        MODELS["coding"],
    ]

    result: list[str] = []
    for model in ordered:
        if model not in result:
            result.append(model)

    return result


def build_payload(request: ChatCompletionRequest, model: str) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "model": model,
        "messages": [
            {
                "role": message.role,
                "content": message.content,
            }
            for message in request.messages
        ],
        "stream": request.stream,
    }

    if request.temperature is not None:
        payload["temperature"] = request.temperature

    if request.max_tokens is not None:
        payload["max_tokens"] = request.max_tokens

    if request.top_p is not None:
        payload["top_p"] = request.top_p

    return payload


def dahl_headers() -> dict[str, str]:
    return {
        "Authorization": f"Bearer {DAHL_API_KEY}",
        "Content-Type": "application/json",
        "Accept": "text/event-stream, application/json",
        "User-Agent": "A1-Dahl-Router/1.0",
    }


def hcnsec_headers() -> dict[str, str]:
    return {
        "Authorization": f"Bearer {HCNSEC_API_KEY}",
        "Content-Type": "application/json",
        "Accept": "text/event-stream, application/json",
        "User-Agent": "A1-HCNSEC-Router/1.1",
    }


async def stream_from_dahl(
    client: httpx.AsyncClient,
    payload: dict[str, Any],
    model: str,
) -> AsyncIterator[bytes]:
    try:
        async with client.stream(
            "POST",
            f"{DAHL_BASE_URL}/chat/completions",
            headers=dahl_headers(),
            json=payload,
        ) as response:
            if response.status_code >= 400:
                body = await response.aread()
                logger.error("Dahl streaming error model=%s status=%s", model, response.status_code)
                yield (
                    b"data: "
                    + json.dumps(
                        {
                            "error": {
                                "message": "Dahl upstream error",
                                "status": response.status_code,
                            }
                        }
                    ).encode()
                    + b"\n\n"
                )
                yield b"data: [DONE]\n\n"
                return

            async for chunk in response.aiter_bytes():
                yield chunk

    except Exception:
        logger.exception("Streaming request failed model=%s", model)
        yield (
            b"data: "
            + json.dumps(
                {"error": {"message": "Streaming request failed"}}
            ).encode()
            + b"\n\n"
        )
        yield b"data: [DONE]\n\n"


async def stream_from_hcnsec(
    client: httpx.AsyncClient,
    payload: dict[str, Any],
    model: str,
) -> AsyncIterator[bytes]:
    try:
        async with client.stream(
            "POST",
            f"{HCNSEC_BASE_URL}/chat/completions",
            headers=hcnsec_headers(),
            json=payload,
        ) as response:
            if response.status_code >= 400:
                await response.aread()
                logger.error("HCNSEC streaming error model=%s status=%s", model, response.status_code)
                yield b"data: " + json.dumps(
                    {"error": {"message": "خطا از سرویس HCNSEC", "status": response.status_code}},
                    ensure_ascii=False,
                ).encode() + b"\n\n"
                yield b"data: [DONE]\n\n"
                return
            async for chunk in response.aiter_bytes():
                yield chunk
    except Exception:
        logger.exception("HCNSEC streaming request failed model=%s", model)
        yield b"data: " + json.dumps(
            {"error": {"message": "خطا در ارتباط با سرویس HCNSEC"}},
            ensure_ascii=False,
        ).encode() + b"\n\n"
        yield b"data: [DONE]\n\n"


@app.get("/health")
async def health() -> dict[str, Any]:
    return {
        "status": "ok",
        "service": "a1-llm-router",
        "dahl_configured": bool(DAHL_API_KEY),
        "hcnsec_configured": bool(HCNSEC_API_KEY),
        "default_model": HCNSEC_MODEL,
        "auth_configured": bool(CHATBOX_TOKEN),
    }


@app.get("/v1/models")
async def list_models() -> dict[str, Any]:
    now = int(time.time())

    return {
        "object": "list",
        "data": [
            {
                "id": "auto",
                "object": "model",
                "created": now,
                "owned_by": "a1-router",
            },
            *[
                {
                    "id": model,
                    "object": "model",
                    "created": now,
                "owned_by": "hcnsec" if model == HCNSEC_MODEL else "dahl",
                }
                for model in sorted(ALL_MODELS)
            ],
        ],
    }


@app.post(
    "/v1/chat/completions",
)
async def chat_completions(
    request: ChatCompletionRequest,
) -> Any:
    text = latest_user_text(request.messages)
    candidates = model_sequence(request.model, text)

    logger.info(
        "request=%s selected=%s candidates=%s stream=%s",
        uuid.uuid4().hex[:12],
        candidates[0],
        candidates,
        request.stream,
    )

    selected = candidates[0]
    provider = "hcnsec" if selected == HCNSEC_MODEL else "dahl"

    if provider == "hcnsec" and not HCNSEC_API_KEY:
        raise HTTPException(status_code=503, detail="توکن HCNSEC تنظیم نشده است")
    if provider == "dahl" and not DAHL_API_KEY:
        raise HTTPException(status_code=503, detail="DAHL_API_KEY is not configured")

    if request.stream:
        payload = build_payload(request, candidates[0])
        client = httpx.AsyncClient(timeout=DAHL_TIMEOUT)

        async def close_client() -> AsyncIterator[bytes]:
            try:
                stream = stream_from_hcnsec if provider == "hcnsec" else stream_from_dahl
                async for chunk in stream(client, payload, candidates[0]):
                    yield chunk
            finally:
                await client.aclose()

        return StreamingResponse(
            close_client(),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
            },
        )

    last_error = "No upstream response"

    async with httpx.AsyncClient(timeout=DAHL_TIMEOUT) as client:
        for model in candidates:
            provider = "hcnsec" if model == HCNSEC_MODEL else "dahl"
            if provider == "hcnsec" and not HCNSEC_API_KEY:
                raise HTTPException(status_code=503, detail="توکن HCNSEC تنظیم نشده است")
            if provider == "dahl" and not DAHL_API_KEY:
                continue
            payload = build_payload(request, model)

            try:
                base_url = HCNSEC_BASE_URL if provider == "hcnsec" else DAHL_BASE_URL
                headers = hcnsec_headers() if provider == "hcnsec" else dahl_headers()
                response = await client.post(
                    f"{base_url}/chat/completions",
                    headers=headers,
                    json=payload,
                )

                if response.status_code < 400:
                    result = response.json()
                    result.setdefault("_a1_router", {})
                    result["_a1_router"]["selected_model"] = model
                    return result

                last_error = f"{provider} returned HTTP {response.status_code}"

                logger.warning("provider=%s model=%s failed status=%s", provider, model, response.status_code)

            except httpx.TimeoutException:
                last_error = f"Timeout while calling {model}"
                logger.warning(last_error)

            except Exception as exc:
                last_error = str(exc)
                logger.exception("model=%s failed", model)

    raise HTTPException(
        status_code=502,
        detail={
            "error": "all_upstreams_failed",
            "message": last_error,
        },
    )
