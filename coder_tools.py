import os
import subprocess

class CoderTools:
    @staticmethod
    def read_file(file_path: str) -> str:
        if not os.path.exists(file_path):
            return f"Error: File '{file_path}' not found."
        with open(file_path, "r", encoding="utf-8") as f:
            return f.read()

    @staticmethod
    def write_file(file_path: str, content: str) -> str:
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)
        return f"File '{file_path}' updated successfully."

    @staticmethod
    def run_command(command: str) -> dict:
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        return {"stdout": result.stdout, "stderr": result.stderr, "exit_code": result.returncode}
