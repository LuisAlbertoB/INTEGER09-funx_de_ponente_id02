"""
Endpoint de Búsqueda Semántica de Eventos.
Fase 3 del servicio de Data Mining.

Recibe una consulta, la convierte en un vector, y busca en FAISS
los eventos más similares (por título y descripción).
"""

from fastapi import APIRouter
from app.schemas import IndexEventRequest, SemanticSearchRequest, SemanticSearchResponse, SearchResult
from app.core.models import get_semantic_model
from app.core.vector_store import vector_store

router = APIRouter(prefix="/api/ml/semantico", tags=["Búsqueda Semántica"])


@router.post(
    "/indexar",
    summary="Indexar un evento en la base vectorial",
    description="Convierte el título y descripción de un evento en un embedding y lo guarda en FAISS."
)
async def indexar_evento(req: IndexEventRequest):
    modelo = get_semantic_model()
    
    # Preprocesamiento simple
    texto = f"{req.titulo} {req.descripcion}".strip()
    
    # Generar embedding (retorna un ndarray)
    embedding = modelo.encode([texto])[0]
    
    # Añadir a FAISS
    agregado = vector_store.add_event(req.id_evento, embedding.reshape(1, -1))
    
    if agregado:
        return {"message": "Evento indexado correctamente.", "id_evento": req.id_evento}
    else:
        return {"message": "El evento ya estaba indexado o fue actualizado.", "id_evento": req.id_evento}


@router.post(
    "/buscar",
    response_model=SemanticSearchResponse,
    summary="Buscar eventos similares",
    description="Recibe texto libre y devuelve los eventos que más se parezcan en significado."
)
async def buscar_eventos(req: SemanticSearchRequest):
    modelo = get_semantic_model()
    
    # Generar embedding de la consulta
    query_embedding = modelo.encode([req.query])[0]
    
    # Buscar en FAISS
    resultados = vector_store.search(query_embedding.reshape(1, -1), top_k=req.top_k)
    
    # Mapear a Schema
    resultados_schema = [
        SearchResult(id_evento=r["id_evento"], score=r["score"])
        for r in resultados
    ]
    
    return SemanticSearchResponse(
        query=req.query,
        resultados=resultados_schema
    )
