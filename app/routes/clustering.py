"""
Endpoint para Clustering de Reportes (Topic Modeling).
Agrupa reportes similares automáticamente sin especificar K (número de grupos).
"""

from fastapi import APIRouter, HTTPException
from sklearn.cluster import AgglomerativeClustering
from app.schemas import ClusterRequest, ClusterResponse, ClusterResult
from app.core.models import get_semantic_model
import numpy as np

router = APIRouter(prefix="/api/ml/clustering", tags=["Clustering de Reportes"])

@router.post(
    "/reportes",
    response_model=ClusterResponse,
    summary="Agrupar reportes automáticamente",
    description="Vectoriza los reportes y usa AgglomerativeClustering para encontrar grupos temáticos de forma automática."
)
async def agrupar_reportes(req: ClusterRequest):
    if not req.reportes:
        raise HTTPException(status_code=400, detail="La lista de reportes no puede estar vacía.")
        
    if len(req.reportes) < 2:
        # Si hay 0 o 1 reporte, todos van al cluster 0
        resultados = [
            ClusterResult(id_reporte=r.id_reporte, cluster_id=0) 
            for r in req.reportes
        ]
        return ClusterResponse(total_clusters=1 if req.reportes else 0, resultados=resultados)

    modelo = get_semantic_model()
    
    # 1. Extraer los textos
    textos = [r.texto for r in req.reportes]
    
    # 2. Generar embeddings (matriz N x 768)
    embeddings = modelo.encode(textos)
    
    # 3. Aplicar clustering automático
    # Usamos cosine distance en AgglomerativeClustering
    # distance_threshold determina cuándo dejar de agrupar. 
    # Un threshold de 0.5 con métrica de coseno suele funcionar bien para separar temas distintos.
    clustering = AgglomerativeClustering(
        n_clusters=None, 
        metric='cosine', 
        linkage='average',
        distance_threshold=0.5
    )
    
    labels = clustering.fit_predict(embeddings)
    
    # Encontrar número de clusters
    total_clusters = len(set(labels))
    
    # 4. Mapear resultados
    resultados = []
    for i, reporte in enumerate(req.reportes):
        resultados.append(
            ClusterResult(
                id_reporte=reporte.id_reporte,
                cluster_id=int(labels[i])
            )
        )
        
    return ClusterResponse(
        total_clusters=total_clusters,
        resultados=resultados
    )
