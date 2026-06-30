"""
Schemas de entrada y salida para los endpoints de NLP.
Usamos Pydantic para validar automáticamente los datos.
"""

from pydantic import BaseModel, Field
from typing import Optional


# ══════════════════════════════════════════════════════════════════════════
#  NER (Extracción de Entidades)
# ══════════════════════════════════════════════════════════════════════════

class NERRequest(BaseModel):
    """Texto del cual extraer entidades nombradas."""
    texto: str = Field(
        ...,
        min_length=3,
        max_length=2000,
        examples=["Hay un cristal roto en el Edificio A, cerca del Aula A-101."]
    )


class Entity(BaseModel):
    """Una entidad detectada por el modelo."""
    palabra: str
    tipo: str          # PER, LOC, ORG, MISC
    confianza: float   # 0.0 a 1.0


class NERResponse(BaseModel):
    """Respuesta del endpoint NER."""
    texto_original: str
    entidades: list[Entity]
    total_entidades: int


# ══════════════════════════════════════════════════════════════════════════
#  Análisis de Sentimientos
# ══════════════════════════════════════════════════════════════════════════

class SentimentRequest(BaseModel):
    """Texto para analizar sentimiento."""
    texto: str = Field(
        ...,
        min_length=3,
        max_length=2000,
        examples=["El taller estuvo muy aburrido y el ponente llegó tarde."]
    )


class SentimentResponse(BaseModel):
    """Respuesta del endpoint de sentimiento."""
    texto_original: str
    label: str          # POSITIVO, NEUTRAL, NEGATIVO
    estrellas: int      # 1 a 5
    confianza: float    # 0.0 a 1.0


# ══════════════════════════════════════════════════════════════════════════
#  Búsqueda Semántica
# ══════════════════════════════════════════════════════════════════════════

class IndexEventRequest(BaseModel):
    """Datos para indexar un evento en FAISS."""
    id_evento: int
    titulo: str
    descripcion: Optional[str] = ""

class SemanticSearchRequest(BaseModel):
    """Consulta para buscar eventos similares."""
    query: str = Field(
        ...,
        min_length=2,
        max_length=500,
        examples=["crisis hidrica"]
    )
    top_k: int = Field(default=5, ge=1, le=20)

class SearchResult(BaseModel):
    """Resultado individual de búsqueda."""
    id_evento: int
    score: float

class SemanticSearchResponse(BaseModel):
    """Respuesta de búsqueda semántica."""
    query: str
    resultados: list[SearchResult]

# ══════════════════════════════════════════════════════════════════════════
#  Health Check
# ══════════════════════════════════════════════════════════════════════════

class HealthResponse(BaseModel):
    status: str
    message: str
    modelos_cargados: list[str]
    environment: str
    vectores_indexados: int = 0
