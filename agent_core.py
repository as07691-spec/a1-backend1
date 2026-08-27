import logging
from coding_agent import CodingAgent

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("A1-AgentCore")

class AgentCore:
    def __init__(self):
        self.agent = CodingAgent()
        logger.info("A1 Agent Core initialized.")

    async def process_task(self, task_type: str, path: str, content: str = None):
        """
        مدیریت چرخه وظایف: read, write, execute
        """
        logger.info(f"Processing task: {task_type} on {path}")
        try:
            result = self.agent.run(task_type, path, content)
            return {"status": "success", "data": result}
        except Exception as e:
            logger.error(f"Task failed: {str(e)}")
            return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    import asyncio
    core = AgentCore()
    # تست سریع: خواندن فایل ابزارها
    loop = asyncio.get_event_loop()
    res = loop.run_until_complete(core.process_task("read", "/opt/a1/backend/coder_tools.py"))
    print(f"Core Self-Test (Read): {res['status']}")
