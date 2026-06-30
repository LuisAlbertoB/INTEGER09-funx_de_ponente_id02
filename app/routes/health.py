"""
Endpoint de salud del servicio NLP.
"""

from fastapi import APIRouter
from app.schemas import HealthResponse
from app.core.config import get_settings
from app.core.models import _models
from app.core.vector_store import vector_store

router = APIRouter(tags=["Health"])


@router.get(
    "/api/health",
    response_model=HealthResponse,
    summary="Estado del servicio NLP"
)
async def health_check():
    settings = get_settings()
    
    # Obtener el número de vectores si el índice está cargado
    num_vectores = vector_store.index.ntotal if vector_store.index else 0
    
    return HealthResponse(
        status="OK",
        message="Servicio NLP corriendo correctamente.",
        modelos_cargados=list(_models.keys()),
        environment=settings.environment,
        vectores_indexados=num_vectores
    )
