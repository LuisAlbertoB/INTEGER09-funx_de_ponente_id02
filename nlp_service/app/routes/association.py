"""
Endpoint para Asociación de Reportes.
Reemplaza el antiguo modelo de Clustering ciego.
Usa NER y Sentiment para enriquecer los reportes cruzando entidades con PostgreSQL.
"""

from fastapi import APIRouter, HTTPException
from app.schemas import AssociationRequest, AssociationResponse, ReporteAsociado
from app.core.models import get_ner_pipeline, get_sentiment_pipeline
from transformers import pipeline

router = APIRouter(prefix="/api/ml/asociar", tags=["Asociación de Reportes"])

def fuzzy_match(palabra: str, lista_conocida: list[str]) -> str | None:
    """Busca una coincidencia parcial simple en la lista conocida."""
    palabra_lower = palabra.lower()
    for item in lista_conocida:
        if palabra_lower in item.lower() or item.lower() in palabra_lower:
            return item
    return None

@router.post(
    "/reportes",
    response_model=AssociationResponse,
    summary="Enriquecer y asociar reportes",
    description="Usa NER para detectar aulas, personas y mobiliario; luego usa Sentiment para asignar prioridad."
)
async def asociar_reportes(req: AssociationRequest):
    if not req.reportes:
        raise HTTPException(status_code=400, detail="La lista de reportes no puede estar vacía.")

    ner_pipeline = get_ner_pipeline()
    sentiment_pipeline = get_sentiment_pipeline()
    
    resultados = []
    
    for reporte in req.reportes:
        texto = reporte.texto
        
        # 1. Analizar Sentimiento
        sent_result = sentiment_pipeline(texto[:512])[0]
        stars = int(sent_result['label'].split(' ')[0])
        
        sentimiento_label = "NEUTRAL"
        importancia = "MEDIA"
        
        if stars >= 4:
            sentimiento_label = "POSITIVO"
            importancia = "BAJA" # Lo positivo no suele ser urgente de arreglar
        elif stars <= 2:
            sentimiento_label = "NEGATIVO"
            importancia = "ALTA" # Lo negativo (quejas/daños) es urgente
            
        # 2. Analizar Entidades (NER)
        ner_results = ner_pipeline(texto[:512])
        
        aula_detectada = None
        docente_detectado = None
        mobiliario_detectado = None
        
        # Agrupar tokens subwords (##)
        palabras_completas = []
        palabra_actual = ""
        tipo_actual = ""
        
        for entity in ner_results:
            word = entity['word']
            tipo = entity['entity_group']
            
            if word.startswith("##"):
                palabra_actual += word[2:]
            else:
                if palabra_actual:
                    palabras_completas.append((palabra_actual, tipo_actual))
                palabra_actual = word
                tipo_actual = tipo
                
        if palabra_actual:
            palabras_completas.append((palabra_actual, tipo_actual))
            
        # 3. Cruzar con el Contexto (Fuzzy Matching simple sobre NER)
        for palabra, tipo in palabras_completas:
            if tipo == "LOC" and not aula_detectada:
                aula_detectada = fuzzy_match(palabra, req.contexto.aulas) or palabra
            
            elif tipo == "PER" and not docente_detectado:
                docente_detectado = fuzzy_match(palabra, req.contexto.docentes) or palabra
                
            elif (tipo == "ORG" or tipo == "MISC") and not mobiliario_detectado:
                mobiliario_detectado = fuzzy_match(palabra, req.contexto.mobiliario) or palabra
                
        # 3.5 Fallback: Búsqueda directa en el texto para palabras comunes que el NER ignora
        if not aula_detectada:
            aula_detectada = fuzzy_match(texto, req.contexto.aulas)
        if not docente_detectado:
            docente_detectado = fuzzy_match(texto, req.contexto.docentes)
        if not mobiliario_detectado:
            mobiliario_detectado = fuzzy_match(texto, req.contexto.mobiliario)
                
        # 4. Crear resultado
        resultados.append(ReporteAsociado(
            id_reporte=reporte.id_reporte,
            fecha=reporte.fecha,
            aula_detectada=aula_detectada,
            docente_detectado=docente_detectado,
            mobiliario_detectado=mobiliario_detectado,
            sentimiento_label=sentimiento_label,
            importancia=importancia
        ))

    return AssociationResponse(
        total_procesados=len(resultados),
        resultados=resultados
    )
