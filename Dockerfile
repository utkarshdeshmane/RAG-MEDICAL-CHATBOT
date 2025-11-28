############################################
# STAGE 1 — BUILDER
############################################
FROM python:3.10-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /build

# Install system packages required to build Python deps
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY . .

# Install dependencies into a virtual environment
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir -e .


############################################
# STAGE 2 — FINAL RUNTIME IMAGE
############################################
FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

# Activate venv for all future commands
ENV PATH="/opt/venv/bin:$PATH"

# Copy only source code (not build tools)
COPY . .

# Expose Flask port
EXPOSE 5000

# Start your app
CMD ["python", "app/application.py"]