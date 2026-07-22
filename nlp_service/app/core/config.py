"""
Configuración centralizada del servicio NLP.
Lee las variables de entorno desde .env y las expone como un objeto tipado.
"""

from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # ── Servidor ───────────────────────────────────────────
    nlp_port: int = 8000
    environment: str = "development"

    # ── API Principal ──────────────────────────────────────
    api_principal_url: str = "http://localhost:3000"

    # ── Modelos de IA ──────────────────────────────────────
    ner_model: str = "Davlan/bert-base-multilingual-cased-ner-hrl"
    sentiment_model: str = "nlptown/bert-base-multilingual-uncased-sentiment"
    semantic_model: str = "hiiamsid/sentence_similarity_spanish_es"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    """Singleton cacheado para no leer .env en cada request."""
    return Settings()
