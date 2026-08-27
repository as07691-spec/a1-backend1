from coder_tools import CoderTools

class CodingAgent:
    def __init__(self):
        self.tools = CoderTools()

    def inspect_workspace(self, base_path: str = "/opt/a1/backend"):
        result = self.tools.run_command(f"ls -la {base_path}")
        return result

    def read_target(self, path: str):
        return self.tools.read_file(path)

    def write_target(self, path: str, content: str):
        return self.tools.write_file(path, content)

    def execute_task(self, command: str):
        return self.tools.run_command(command)

if __name__ == "__main__":
    agent = CodingAgent()
    check = agent.inspect_workspace()
    print("Agent Initialized Successfully. Workspace check exit code:", check["exit_code"])
