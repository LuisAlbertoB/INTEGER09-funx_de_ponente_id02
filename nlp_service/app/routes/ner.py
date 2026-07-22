"""
Endpoint de Extracción de Entidades Nombradas (NER).
Fase 1 del servicio de Data Mining.

Recibe un texto en español y devuelve las entidades detectadas
(Personas, Ubicaciones, Organizaciones) usando BERT multilingüe.
"""

from fastapi import APIRouter
from app.schemas import NERRequest, NERResponse, Entity
from app.core.models import get_ner_pipeline

router = APIRouter(prefix="/api/ml/ner", tags=["NER"])


@router.post(
    "/analizar",
    response_model=NERResponse,
    summary="Extraer entidades de un texto",
    description="Detecta automáticamente Personas (PER), Ubicaciones (LOC), "
                "Organizaciones (ORG) y Misceláneos (MISC) en texto libre."
)
async def analizar_entidades(req: NERRequest):
    ner = get_ner_pipeline()

    # Ejecutar el modelo NER sobre el texto
    resultados_raw = ner(req.texto)

    # Transformar la salida de HuggingFace a nuestro schema limpio
    entidades = [
        Entity(
            palabra=r["word"],
            tipo=r["entity_group"],
            confianza=round(float(r["score"]), 4),
        )
        for r in resultados_raw
    ]

    return NERResponse(
        texto_original=req.texto,
        entidades=entidades,
        total_entidades=len(entidades),
    )
