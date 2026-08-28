"""
Git Management Engine for A1 Studio.
Enables UI and API clients to inspect repository status, commit changes, and push upstream.
Handles clean working tree states gracefully.
"""

import subprocess
from typing import Dict, Any

class GitEngine:
    def __init__(self, repo_path: str = "/opt/a1/backend"):
        self.repo_path = repo_path

    def _run_git(self, args: list) -> Dict[str, Any]:
        """Execute a git command and return a structured response dictionary."""
        try:
            result = subprocess.run(
                ["git"] + args,
                cwd=self.repo_path,
                capture_output=True,
                text=True,
                check=True
            )
            return {"success": True, "output": result.stdout.strip(), "error": None}
        except subprocess.CalledProcessError as e:
            stdout_msg = e.stdout.strip() if e.stdout else ""
            stderr_msg = e.stderr.strip() if e.stderr else ""
            combined_msg = f"{stdout_msg}\n{stderr_msg}".strip()
            
            # If nothing to commit, treat as clean state success
            if "nothing to commit" in combined_msg or "working tree clean" in combined_msg:
                return {"success": True, "output": "Working tree clean. No changes to commit.", "error": None}
                
            return {"success": False, "output": stdout_msg, "error": stderr_msg or stdout_msg}

    def get_status(self) -> Dict[str, Any]:
        """Retrieve short status of working directory."""
        return self._run_git(["status", "--short"])

    def commit_and_push(self, message: str) -> Dict[str, Any]:
        """Stage all modifications, commit if necessary, and push to main branch."""
        if not message or not message.strip():
            return {"success": False, "output": "", "error": "Commit message cannot be empty."}

        # 1. Stage all changes
        add_res = self._run_git(["add", "."])
        if not add_res["success"]:
            return add_res

        # 2. Check status before commit to avoid false error
        status_res = self._run_git(["status", "--porcelain"])
        if not status_res["output"]:
            return {"success": True, "output": "Repository is up-to-date. No new changes to commit.", "error": None}

        # 3. Commit staged changes
        commit_res = self._run_git(["commit", "-m", message])
        if not commit_res["success"]:
            return commit_res

        # 4. Push to remote repository
        push_res = self._run_git(["push", "origin", "main"])
        return push_res

git_engine = GitEngine()
