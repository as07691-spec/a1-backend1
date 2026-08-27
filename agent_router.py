import hashlib
import json
import os
import secrets
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Literal

from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel, Field


WORKSPACE = Path("/opt/a1/backend").resolve()
DATA_DIR = WORKSPACE / "agent_data"
DB_PATH = DATA_DIR / "a1_agent.db"
KEY_PATH = DATA_DIR / "api_key"

SENSITIVE_NAMES = {
    ".env",
    ".env.local",
    ".env.production",
    "a1-agent.service",
    "market-data.conf",
}

TaskStatus = Literal[
    "draft",
    "planned",
    "backup_created",
    "running",
    "tested",
    "waiting_for_approval",
    "approved",
    "rejected",
    "rolled_back",
    "failed",
]

router = APIRouter(tags=["agent"])


class TaskCreate(BaseModel):
    title: str = Field(min_length=3, max_length=200)
    goal: str = Field(min_length=3, max_length=5000)
    acceptance_criteria: list[str] = Field(min_length=1, max_length=50)
    constraints: list[str] = Field(default_factory=list, max_length=50)
    allowed_files: list[str] = Field(min_length=1, max_length=50)
    scope: Literal["frontend"] = "frontend"


class TaskDecision(BaseModel):
    note: str = Field(default="", max_length=2000)


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def ensure_storage() -> None:
    DATA_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)

    if not KEY_PATH.exists():
        KEY_PATH.write_text(secrets.token_urlsafe(32), encoding="utf-8")
        os.chmod(KEY_PATH, 0o600)

    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS tasks (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                goal TEXT NOT NULL,
                acceptance_criteria TEXT NOT NULL,
                constraints_json TEXT NOT NULL,
                allowed_files_json TEXT NOT NULL,
                scope TEXT NOT NULL,
                task_status TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                decision_note TEXT NOT NULL DEFAULT ''
            )
            """
        )
        conn.commit()

    os.chmod(DB_PATH, 0o600)


def get_api_key() -> str:
    ensure_storage()
    return KEY_PATH.read_text(encoding="utf-8").strip()


def require_api_key(x_a1_api_key: str | None = Header(default=None)) -> None:
    expected = get_api_key()
    if not x_a1_api_key or not secrets.compare_digest(x_a1_api_key, expected):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key is missing or invalid.",
        )


def validate_frontend_file(relative_path: str) -> str:
    raw = relative_path.strip()

    if not raw:
        raise HTTPException(status_code=422, detail="allowed_files cannot contain an empty path.")

    candidate = (WORKSPACE / raw).resolve()

    try:
        candidate.relative_to(WORKSPACE)
    except ValueError as exc:
        raise HTTPException(
            status_code=422,
            detail=f"Path outside workspace is forbidden: {relative_path}",
        ) from exc

    parts = candidate.parts
    if any(part in SENSITIVE_NAMES for part in parts):
        raise HTTPException(
            status_code=422,
            detail=f"Sensitive file is forbidden: {relative_path}",
        )

    try:
        relative = candidate.relative_to(WORKSPACE)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail="Invalid workspace path.") from exc

    if not str(relative).startswith("static/"):
        raise HTTPException(
            status_code=422,
            detail="Frontend tasks may only use files under static/.",
        )

    if candidate.suffix.lower() not in {".html", ".css", ".js", ".json", ".svg"}:
        raise HTTPException(
            status_code=422,
            detail="Unsupported frontend file extension.",
        )

    return str(relative)


def task_to_dict(row: sqlite3.Row) -> dict:
    return {
        "id": row["id"],
        "title": row["title"],
        "goal": row["goal"],
        "acceptance_criteria": json.loads(row["acceptance_criteria"]),
        "constraints": json.loads(row["constraints_json"]),
        "allowed_files": json.loads(row["allowed_files_json"]),
        "scope": row["scope"],
        "status": row["task_status"],
        "created_at": row["created_at"],
        "updated_at": row["updated_at"],
        "decision_note": row["decision_note"],
    }


def get_task_or_404(task_id: str) -> sqlite3.Row:
    ensure_storage()
    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        row = conn.execute("SELECT * FROM tasks WHERE id = ?", (task_id,)).fetchone()

    if row is None:
        raise HTTPException(status_code=404, detail="Task not found.")

    return row


@router.get("/status")
async def get_status():
    ensure_storage()
    return {
        "agent_status": "active",
        "workspace": str(WORKSPACE),
        "task_storage": str(DB_PATH),
        "coding_execution_enabled": False,
        "supported_actions": [
            "create_task",
            "list_tasks",
            "get_task",
            "approve_task",
            "reject_task",
        ],
        "security": {
            "api_key_required_for_task_routes": True,
            "raw_shell_execution_exposed": False,
            "frontend_workspace_only": True,
        },
    }


@router.post("/tasks", status_code=status.HTTP_201_CREATED)
async def create_task(payload: TaskCreate, _: None = require_api_key):
    ensure_storage()

    allowed_files = [validate_frontend_file(path) for path in payload.allowed_files]
    task_id = secrets.token_hex(12)
    timestamp = now_iso()

    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            INSERT INTO tasks (
                id, title, goal, acceptance_criteria, constraints_json,
                allowed_files_json, scope, task_status, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                task_id,
                payload.title.strip(),
                payload.goal.strip(),
                json.dumps(payload.acceptance_criteria, ensure_ascii=False),
                json.dumps(payload.constraints, ensure_ascii=False),
                json.dumps(allowed_files, ensure_ascii=False),
                payload.scope,
                "planned",
                timestamp,
                timestamp,
            ),
        )
        conn.commit()

    return task_to_dict(get_task_or_404(task_id))


@router.get("/tasks")
async def list_tasks(_: None = require_api_key):
    ensure_storage()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        rows = conn.execute(
            "SELECT * FROM tasks ORDER BY created_at DESC"
        ).fetchall()

    return {"items": [task_to_dict(row) for row in rows], "count": len(rows)}


@router.get("/tasks/{task_id}")
async def get_task(task_id: str, _: None = require_api_key):
    return task_to_dict(get_task_or_404(task_id))


@router.post("/tasks/{task_id}/approve")
async def approve_task(task_id: str, payload: TaskDecision, _: None = require_api_key):
    task = get_task_or_404(task_id)

    if task["task_status"] != "waiting_for_approval":
        raise HTTPException(
            status_code=409,
            detail="Only tasks in waiting_for_approval can be approved.",
        )

    timestamp = now_iso()
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            UPDATE tasks
            SET task_status = ?, decision_note = ?, updated_at = ?
            WHERE id = ?
            """,
            ("approved", payload.note.strip(), timestamp, task_id),
        )
        conn.commit()

    return task_to_dict(get_task_or_404(task_id))


@router.post("/tasks/{task_id}/reject")
async def reject_task(task_id: str, payload: TaskDecision, _: None = require_api_key):
    task = get_task_or_404(task_id)

    if task["task_status"] not in {"planned", "waiting_for_approval"}:
        raise HTTPException(
            status_code=409,
            detail="Only planned or waiting_for_approval tasks can be rejected.",
        )

    timestamp = now_iso()
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            UPDATE tasks
            SET task_status = ?, decision_note = ?, updated_at = ?
            WHERE id = ?
            """,
            ("rejected", payload.note.strip(), timestamp, task_id),
        )
        conn.commit()

    return task_to_dict(get_task_or_404(task_id))
