/**
 * Cliente HTTP para comunicarse con el Servicio NLP (Python/FastAPI).
 * 
 * Diseño: "Fire and Forget" (Asíncrono en Segundo Plano)
 * ─────────────────────────────────────────────────────────
 * Las llamadas al servicio de IA se ejecutan en segundo plano.
 * Si el servicio NLP está caído o demora, el flujo principal
 * del usuario NO se ve afectado. El reporte/evaluación se guarda
 * de todas formas, y la IA lo enriquece después.
 */

const axios = require('axios');

const NLP_BASE_URL = process.env.NLP_SERVICE_URL || 'http://localhost:8000';

// Cliente con timeout extendido para el endpoint de asociación masiva de reportes
const nlpClient = axios.create({
  baseURL: NLP_BASE_URL,
  timeout: 300000, // 5 minutos — soporta hasta ~200 reportes sin agotar el tiempo
  headers: { 'Content-Type': 'application/json' }
});

/**
 * Extrae entidades nombradas (Personas, Ubicaciones, Organizaciones)
 * de un texto en español.
 * @param {string} texto - El texto a analizar
 * @returns {Promise<{entidades: Array, total_entidades: number}>}
 */
const analizarEntidades = async (texto) => {
  try {
    const { data } = await nlpClient.post('/api/ml/ner/analizar', { texto });
    console.log(`🧠 NER: ${data.total_entidades} entidades detectadas.`);
    return data;
  } catch (error) {
    console.error('⚠️  NLP (NER) no disponible:', error.message);
    return null; // No bloquear el flujo principal
  }
};

/**
 * Analiza el sentimiento de un texto (POSITIVO, NEUTRAL, NEGATIVO).
 * @param {string} texto - El comentario/evaluación a analizar
 * @returns {Promise<{label: string, estrellas: number, confianza: number}>}
 */
const evaluarSentimiento = async (texto) => {
  try {
    const { data } = await nlpClient.post('/api/ml/sentimiento/evaluar', { texto });
    console.log(`🧠 Sentimiento: ${data.label} (${data.estrellas}⭐, ${(data.confianza * 100).toFixed(1)}%)`);
    return data;
  } catch (error) {
    console.error('⚠️  NLP (Sentimiento) no disponible:', error.message);
    return null;
  }
};

/**
 * Indexa un evento en FAISS para búsquedas semánticas.
 * @param {number} id_evento 
 * @param {string} titulo 
 * @param {string} descripcion 
 * @returns {Promise<boolean>}
 */
const indexarEvento = async (id_evento, titulo, descripcion) => {
  try {
    await nlpClient.post('/api/ml/semantico/indexar', { id_evento, titulo, descripcion });
    console.log(`🧠 Semantic: Evento #${id_evento} indexado en FAISS.`);
    return true;
  } catch (error) {
    console.error('⚠️  NLP (Semantic Index) no disponible:', error.message);
    return false;
  }
};

/**
 * Busca eventos similares por semántica.
 * @param {string} query - Consulta de búsqueda
 * @param {number} top_k - Cantidad de resultados
 * @returns {Promise<Array<{id_evento: number, score: number}>>}
 */
const buscarEventosSemanticos = async (query, top_k = 5) => {
  try {
    const { data } = await nlpClient.post('/api/ml/semantico/buscar', { query, top_k });
    console.log(`🧠 Semantic Search: Encontrados ${data.resultados.length} resultados para "${query}".`);
    return data.resultados;
  } catch (error) {
    console.error('⚠️  NLP (Semantic Search) no disponible:', error.message);
    return [];
  }
};

/**
 * Obtiene recomendaciones basadas en el historial del usuario.
 * @param {Array<number>} history_ids - Lista de IDs de eventos que le interesan al usuario.
 * @param {number} top_k - Cantidad de recomendaciones a retornar.
 * @returns {Promise<Array<{id_evento: number, score: number}>>}
 */
const obtenerRecomendaciones = async (history_ids, top_k = 3) => {
  try {
    const { data } = await nlpClient.post('/api/ml/semantico/recomendaciones', { history_ids, top_k });
    console.log(`🧠 Semantic Recommend: Generadas ${data.resultados.length} recomendaciones.`);
    return data.resultados;
  } catch (error) {
    console.error('⚠️  NLP (Recommend) no disponible:', error.message);
    return [];
  }
};

/**
 * Asocia una lista de reportes extrayendo entidades y sentimiento.
 * Para conjuntos grandes (>30), divide en lotes de 25 para no sobrecargar el
 * microservicio Python en instancias EC2 pequeñas (t3.small).
 *
 * @param {Array<{id_reporte: number, texto: string, fecha: string}>} reportes
 * @param {Object} contexto - Contexto de la base de datos (aulas, docentes, mobiliario).
 * @returns {Promise<{total_procesados: number, resultados: Array}>}
 */
const agruparReportes = async (reportes, contexto) => {
  const BATCH_SIZE = 25;

  if (reportes.length === 0) return { total_procesados: 0, resultados: [] };

  try {
    // Si el conjunto es pequeño, una sola llamada
    if (reportes.length <= BATCH_SIZE) {
      const { data } = await nlpClient.post('/api/ml/asociar/reportes', { reportes, contexto });
      console.log(`🧠 Asociación: Procesados ${data.total_procesados} reportes (lote único).`);
      return data;
    }

    // Para conjuntos grandes: dividir en lotes y combinar resultados
    console.log(`🧠 Asociación: ${reportes.length} reportes → procesando en lotes de ${BATCH_SIZE}...`);
    const todosResultados = [];

    for (let i = 0; i < reportes.length; i += BATCH_SIZE) {
      const lote = reportes.slice(i, i + BATCH_SIZE);
      const loteNum = Math.floor(i / BATCH_SIZE) + 1;
      const totalLotes = Math.ceil(reportes.length / BATCH_SIZE);
      console.log(`  → Lote ${loteNum}/${totalLotes} (${lote.length} reportes)...`);

      const { data } = await nlpClient.post('/api/ml/asociar/reportes', { reportes: lote, contexto });
      todosResultados.push(...data.resultados);
    }

    console.log(`🧠 Asociación completada: ${todosResultados.length} reportes procesados en ${Math.ceil(reportes.length / BATCH_SIZE)} lotes.`);
    return { total_procesados: todosResultados.length, resultados: todosResultados };

  } catch (error) {
    console.error('⚠️  NLP (Asociación) no disponible:', error.message);
    return null;
  }
};

/**
 * Verifica si el servicio NLP está disponible.
 * @returns {Promise<boolean>}
 */
const healthCheck = async () => {
  try {
    const { data } = await nlpClient.get('/api/health');
    return data.status === 'OK';
  } catch {
    return false;
  }
};

module.exports = { 
  analizarEntidades, 
  evaluarSentimiento, 
  indexarEvento, 
  buscarEventosSemanticos, 
  obtenerRecomendaciones,
  agruparReportes,
  healthCheck 
};
