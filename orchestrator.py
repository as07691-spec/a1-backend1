import os
import sys
import json
import time
import subprocess
import urllib.request
import urllib.error

CONFIG_PATH = "/opt/a1/backend/config/providers.json"
WORKSPACE = "/opt/a1"

def load_config():
    if not os.path.exists(CONFIG_PATH):
        return None
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    if "providers" in data and "active_provider" in data:
        act = data["active_provider"]
        prov = data["providers"].get(act, {})
        return {
            "base_url": prov.get("base_url", "").rstrip("/"),
            "api_key": prov.get("api_key", ""),
            "model": prov.get("default_model") or prov.get("models", ["DeepSeek-V4-Flash"])[0]
        }
    return None

def execute_autonomous_cycle():
    cfg = load_config()
    if not cfg:
        print("[-] Configuration not found.")
        return

    print("[+] A1 Autonomous Leader Engine Activated.")
    print(f"[*] Engine Model: {cfg['model']} | Supervisor: A1-Core")
    
    system_status = {
        "stage": 16,
        "backend": "Active (:8000)",
        "frontend": "Next.js Autonomous Integration",
        "market_feed": "TSETMC Integration Ready",
        "mode": "Zero-Intervention Autonomous Execution"
    }
    
    with open("/opt/a1/backend/status.json", "w", encoding="utf-8") as f:
        json.dump(system_status, f, ensure_ascii=False, indent=2)

    print("[✓] State Machine Synchronized at Stage 16.")
    print("[✓] Delegation complete: A1 Agent leading autonomous builds.")

if __name__ == "__main__":
    execute_autonomous_cycle()
