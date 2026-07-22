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

class RecommendEventRequest(BaseModel):
    """Solicita recomendaciones basadas en el historial."""
    history_ids: list[int]
    top_k: int = Field(default=3, ge=1, le=10)

class SearchResult(BaseModel):
    """Resultado individual de búsqueda."""
    id_evento: int
    score: float

class SemanticSearchResponse(BaseModel):
    """Respuesta de búsqueda semántica."""
    query: str
    resultados: list[SearchResult]

class RecommendResponse(BaseModel):
    """Respuesta de recomendaciones."""
    history_ids: list[int]
    resultados: list[SearchResult]

# ══════════════════════════════════════════════════════════════════════════
#  Asociación de Reportes (Reemplaza Clustering)
# ══════════════════════════════════════════════════════════════════════════

class ReporteItem(BaseModel):
    """Un reporte individual para analizar."""
    id_reporte: int
    texto: str
    fecha: str
    
class ContextoBD(BaseModel):
    """Diccionario de contexto desde PostgreSQL."""
    aulas: list[str] = []
    docentes: list[str] = []
    mobiliario: list[str] = []

class AssociationRequest(BaseModel):
    """Solicitud para enriquecer y asociar reportes."""
    reportes: list[ReporteItem]
    contexto: ContextoBD

class ReporteAsociado(BaseModel):
    """Un reporte enriquecido con metadatos NLP."""
    id_reporte: int
    fecha: str
    aula_detectada: Optional[str] = None
    docente_detectado: Optional[str] = None
    mobiliario_detectado: Optional[str] = None
    sentimiento_label: str
    importancia: str # ALTA, MEDIA, BAJA

class AssociationResponse(BaseModel):
    """Respuesta con los reportes enriquecidos."""
    total_procesados: int
    resultados: list[ReporteAsociado]

# ══════════════════════════════════════════════════════════════════════════
#  Health Check
# ══════════════════════════════════════════════════════════════════════════

class HealthResponse(BaseModel):
    status: str
    message: str
    modelos_cargados: list[str]
    environment: str
    vectores_indexados: int = 0
