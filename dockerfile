# Base Image
FROM python:3.12-slim

# Install UV
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app 

# Copy requirements file
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy .env file
COPY .env .env

# Copy dependency files first
COPY pyproject.toml uv.lock ./

#Install dependencies using UV
RUN uv sync --frozen --no-dev

# Copy application code
COPY api/ ./api/

# Set PYTHONPATH so imports resolve
ENV PYTHONPATH=:/app

EXPOSE 8000

# Start the API with uvicorn
CMD ["uv", "run", "uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]