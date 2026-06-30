"""
Gestor del ciclo de vida de los modelos de Machine Learning.
Carga los modelos UNA sola vez al iniciar el servidor y los mantiene
en memoria para todas las peticiones. Esto evita cargar el modelo
en cada request (que tomaría ~5 segundos cada vez).
"""

from transformers import pipeline
from sentence_transformers import SentenceTransformer
from app.core.config import get_settings

# ── Estado global de los modelos ───────────────────────────────────────
_models: dict = {}


def load_models():
    """
    Carga todos los modelos al iniciar el servidor.
    Se llama UNA vez desde el evento 'lifespan' de FastAPI.
    """
    settings = get_settings()

    print("🧠 Cargando modelo NER...")
    _models["ner"] = pipeline(
        "ner",
        model=settings.ner_model,
        aggregation_strategy="simple",
        device=-1,  # -1 = CPU (sin GPU)
    )
    print(f"   ✅ NER listo: {settings.ner_model}")

    print("🧠 Cargando modelo de Sentimientos...")
    _models["sentiment"] = pipeline(
        "text-classification",
        model=settings.sentiment_model,
        device=-1,
    )
    print(f"   ✅ Sentimientos listo: {settings.sentiment_model}")

    print("🧠 Cargando modelo de Búsqueda Semántica...")
    _models["semantic"] = SentenceTransformer(settings.semantic_model, device="cpu")
    print(f"   ✅ Semántica listo: {settings.semantic_model}")

    print("══════════════════════════════════════════════")
    print("  🚀 Todos los modelos cargados exitosamente")
    print("══════════════════════════════════════════════")


def get_ner_pipeline():
    """Retorna el pipeline NER ya cargado."""
    return _models.get("ner")


def get_sentiment_pipeline():
    """Retorna el pipeline de sentimientos ya cargado."""
    return _models.get("sentiment")

def get_semantic_model():
    """Retorna el modelo SentenceTransformer ya cargado."""
    return _models.get("semantic")
