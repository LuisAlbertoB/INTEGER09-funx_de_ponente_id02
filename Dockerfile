# ══════════════════════════════════════════════════════════
#  NLP Data Mining Service — Dockerfile
#  Imagen ligera basada en Debian Bookworm (familia Ubuntu)
# ══════════════════════════════════════════════════════════
FROM python:3.12-slim-bookworm

# Evitar prompts interactivos y configurar locale
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    HF_HOME=/app/models_cache

WORKDIR /app

# Instalar dependencias del sistema mínimas
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Instalar dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cpu -r requirements.txt

# Copiar el código fuente
COPY . .

# Crear directorio para cache de modelos de HuggingFace
RUN mkdir -p /app/models_cache

# Exponer el puerto del servicio
EXPOSE 8000

# Health check para Docker Compose
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8000/api/health || exit 1

# Arrancar con Gunicorn + Uvicorn workers (producción)
CMD ["gunicorn", "app.main:app", \
     "--worker-class", "uvicorn.workers.UvicornWorker", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "1", \
     "--timeout", "120"]
