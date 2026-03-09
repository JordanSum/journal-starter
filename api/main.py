import logging

from dotenv import load_dotenv
from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

from api.routers.journal_router import router as journal_router

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger=logging.getLogger(__name__)
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.INFO)
logger.addHandler(console_handler)

logger.info("Starting your journal API, have fun!")

app = FastAPI(title="Journal API", description="A simple journal API for tracking daily work, struggles, and intentions")
app.include_router(journal_router)

# Prometheus metrics instrumentation - exposes /metrics endpoint
Instrumentator().instrument(app).expose(app)


@app.get("/health")
def health_check():
    """Health check endpoint for Kubernetes probes."""
    return {"status": "healthy"}
