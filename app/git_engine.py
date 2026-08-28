"""
Git Management Engine for A1 Studio.
Enables the UI to check status, commit changes, and push to remote repository.
"""

import subprocess
from typing import Dict, Any

class GitEngine:
    def __init__(self, repo_path: str = "/opt/a1/backend"):
        self.repo_path = repo_path

    def _run_git(self, args: list) -> Dict[str, Any]:
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
            return {"success": False, "output": e.stdout.strip(), "error": e.stderr.strip()}

    def get_status(self) -> Dict[str, Any]:
        return self._run_git(["status", "--short"])

    def commit_and_push(self, message: str) -> Dict[str, Any]:
        if not message.strip():
            return {"success": False, "error": "Commit message cannot be empty."}
        
        # 1. git add .
        add_res = self._run_git(["add", "."])
        if not add_res["success"]:
            return add_res

        # 2. git commit -m "..."
        commit_res = self._run_git(["commit", "-m", message])
        # If nothing to commit, return success with notice
        if not commit_res["success"] and "nothing to commit" in commit_res["error"]:
            return {"success": True, "output": "Nothing to commit, working tree clean.", "error": None}
        elif not commit_res["success"]:
            return commit_res

        # 3. git push origin main
        push_res = self._run_git(["push", "origin", "main"])
        return push_res

git_engine = GitEngine()
