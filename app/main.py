"""
NLP Data Mining Service — Punto de entrada principal.

Este microservicio expone modelos de Machine Learning (NER y Sentimientos)
como una API REST consumible por el servidor principal de Node.js.

Los modelos se cargan UNA vez al iniciar (lifespan) y se mantienen
en memoria para responder peticiones en ~50-100ms por request.
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.core.models import load_models
from app.routes import ner, sentiment, health, semantic


# ── Lifespan: carga modelos al arrancar, libera al apagar ──────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Carga los modelos de IA cuando el servidor inicia."""
    print("\n══════════════════════════════════════════════")
    print("  🤖 NLP Data Mining Service — Iniciando...")
    print("══════════════════════════════════════════════\n")
    load_models()
    yield
    print("\n🛑 NLP Service apagado.\n")


# ── Crear la aplicación FastAPI ────────────────────────────────────────
settings = get_settings()

app = FastAPI(
    title="NLP Data Mining Service",
    description=(
        "Microservicio de Inteligencia Artificial para el Marketplace Académico. "
        "Provee endpoints de NER (extracción de entidades), "
        "análisis de sentimientos y búsqueda semántica."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

# ── CORS (solo el servidor Node.js necesita acceso) ────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=[settings.api_principal_url],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Registrar routers ─────────────────────────────────────────────────
app.include_router(health.router)
app.include_router(ner.router)
app.include_router(sentiment.router)
app.include_router(semantic.router)
