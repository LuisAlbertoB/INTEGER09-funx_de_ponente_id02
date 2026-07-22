"""
Endpoint de Análisis de Sentimientos.
Fase 2 del servicio de Data Mining.

Recibe un texto en español y clasifica su sentimiento
como POSITIVO, NEUTRAL o NEGATIVO usando BERT multilingüe.
"""

from fastapi import APIRouter
from app.schemas import SentimentRequest, SentimentResponse
from app.core.models import get_sentiment_pipeline

router = APIRouter(prefix="/api/ml/sentimiento", tags=["Sentimiento"])

# ── Mapeo de estrellas a etiquetas legibles ─────────────────────────────
_STAR_LABELS = {
    "1 star": ("NEGATIVO", 1),
    "2 stars": ("NEGATIVO", 2),
    "3 stars": ("NEUTRAL", 3),
    "4 stars": ("POSITIVO", 4),
    "5 stars": ("POSITIVO", 5),
}


@router.post(
    "/evaluar",
    response_model=SentimentResponse,
    summary="Analizar sentimiento de un texto",
    description="Clasifica un comentario o evaluación como POSITIVO, NEUTRAL o NEGATIVO, "
                "además de asignar una calificación de 1 a 5 estrellas."
)
async def evaluar_sentimiento(req: SentimentRequest):
    sentiment = get_sentiment_pipeline()

    # Ejecutar el modelo de sentimientos
    resultado = sentiment(req.texto[:512])[0]  # BERT tiene límite de 512 tokens

    # Traducir la salida del modelo a nuestro schema
    label_raw = resultado["label"]
    label_es, estrellas = _STAR_LABELS.get(label_raw, ("NEUTRAL", 3))

    return SentimentResponse(
        texto_original=req.texto,
        label=label_es,
        estrellas=estrellas,
        confianza=round(float(resultado["score"]), 4),
    )
