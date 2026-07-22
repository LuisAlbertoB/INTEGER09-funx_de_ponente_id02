const reportesCtrl = require('../controllers/reportes.controller');
const aulasCtrl = require('../controllers/aulas.controller');
const mobiliarioCtrl = require('../controllers/mobiliario.controller');
const usuariosCtrl = require('../controllers/usuarios.controller');
const periodosService = require('../services/periodos.service');
const nlpClient = require('../services/nlp.client');
const AppError = require('../utils/AppError');

const getReportes = async () => {
  return reportesCtrl.findAll();
};

const getReporteById = async (id) => {
  const reporte = await reportesCtrl.findById(id);
  if (!reporte) throw new AppError('Reporte no encontrado.', 404);
  return reporte;
};

const createReporte = async (userId, { titulo, descripcion, id_aula, id_mobiliario_afectado }) => {
  if (!titulo || !id_aula) {
    throw new AppError('El título y el id_aula son requeridos para crear un reporte.', 400);
  }

  // Validar aula
  const aula = await aulasCtrl.findById(Number(id_aula));
  if (!aula) throw new AppError('El aula especificada no existe.', 404);

  // Validar mobiliario si se envió
  if (id_mobiliario_afectado) {
    const mobiliario = await mobiliarioCtrl.findById(Number(id_mobiliario_afectado));
    if (!mobiliario) throw new AppError('El mobiliario especificado no existe.', 404);
  }

  // Obtener periodo activo automáticamente
  const periodoId = await periodosService.getActivePeriod();

  const reporte = await reportesCtrl.create({
    titulo,
    descripcion: descripcion || null,
    id_user_reportante: userId,
    id_aula: Number(id_aula),
    id_mobiliario_afectado: id_mobiliario_afectado ? Number(id_mobiliario_afectado) : null,
    id_periodo: periodoId
  });

  // ── NLP en segundo plano (Fire & Forget) ────────────────────────────
  // Analiza el texto del reporte para extraer entidades (ubicaciones, personas)
  // Si el servicio NLP está caído, el reporte se guarda de todas formas.
  const textoCompleto = `${titulo}. ${descripcion || ''}`.trim();
  nlpClient.analizarEntidades(textoCompleto).then(resultado => {
    if (resultado && resultado.entidades.length > 0) {
      const ubicaciones = resultado.entidades
        .filter(e => e.tipo === 'LOC')
        .map(e => e.palabra);
      const personas = resultado.entidades
        .filter(e => e.tipo === 'PER')
        .map(e => e.palabra);
      console.log(`📋 Reporte #${reporte.id_reporte} → NER: ubicaciones=[${ubicaciones}], personas=[${personas}]`);
    }
  });

  return reporte;
};

const updateReporte = async (userId, userRole, id, data) => {
  const reporte = await getReporteById(id);
  
  // Validar permisos: Solo el admin o el creador del reporte pueden actualizarlo
  if (userRole !== 'admin' && reporte.id_user_reportante !== userId) {
    throw new AppError('No tienes permisos para modificar este reporte.', 403);
  }

  const dataToUpdate = {};
  if (data.titulo !== undefined) dataToUpdate.titulo = data.titulo;
  if (data.descripcion !== undefined) dataToUpdate.descripcion = data.descripcion;
  
  if (data.id_aula !== undefined) {
    const aula = await aulasCtrl.findById(Number(data.id_aula));
    if (!aula) throw new AppError('El aula especificada no existe.', 404);
    dataToUpdate.id_aula = Number(data.id_aula);
  }

  if (data.id_mobiliario_afectado !== undefined) {
    if (data.id_mobiliario_afectado === null) {
      dataToUpdate.id_mobiliario_afectado = null;
    } else {
      const mobiliario = await mobiliarioCtrl.findById(Number(data.id_mobiliario_afectado));
      if (!mobiliario) throw new AppError('El mobiliario especificado no existe.', 404);
      dataToUpdate.id_mobiliario_afectado = Number(data.id_mobiliario_afectado);
    }
  }

  if (Object.keys(dataToUpdate).length === 0) {
    throw new AppError('No se proporcionaron campos para actualizar.', 400);
  }

  return reportesCtrl.update(id, dataToUpdate);
};

const deleteReporte = async (userId, userRole, id) => {
  const reporte = await getReporteById(id);
  if (userRole !== 'admin' && reporte.id_user_reportante !== userId) {
    throw new AppError('No tienes permiso para eliminar este reporte.', 403);
  }
  return reportesCtrl.remove(id);
};

const getClusteringReportes = async () => {
  const reportes = await reportesCtrl.findAll();
  if (!reportes || reportes.length === 0) {
    return { total_reportes: 0, grupos_por_aula: [], grupos_por_docente: [], grupos_por_sentimiento: [] };
  }

  const reportesPayload = reportes.map(r => ({
    id_reporte: r.id_reporte,
    texto: `${r.titulo}. ${r.descripcion || ''}`.trim(),
    fecha: r.fecha_reporte ? r.fecha_reporte.toISOString() : new Date().toISOString()
  }));

  // Contexto real desde la BD para que el NER haga el match correcto
  const aulas = await aulasCtrl.findAll();
  const mobiliarios = await mobiliarioCtrl.findAll();
  const [usuarios, _count] = await usuariosCtrl.findAll();
  
  const contexto = {
    aulas: aulas.map(a => a.nombre_clave || `Aula ${a.id_aula}`),
    docentes: usuarios.map(u => u.nombre_completo),
    mobiliario: mobiliarios.map(m => m.nombre || m.nombre_mobiliario || `Mobiliario ${m.id_mobiliario}`)
  };

  const nlpResult = await nlpClient.agruparReportes(reportesPayload, contexto);
  if (!nlpResult) {
    throw new AppError('Servicio de Inteligencia Artificial (Asociación) no disponible.', 503);
  }

  // ── Las tres agrupaciones significativas ───────────────────────────────────────
  const porAula    = {};
  const porDocente = {};
  const porSentimiento = {
    NEGATIVO: { sentimiento: 'NEGATIVO', reportes: [] },
    NEUTRAL:  { sentimiento: 'NEUTRAL',  reportes: [] },
    POSITIVO: { sentimiento: 'POSITIVO', reportes: [] },
  };

  nlpResult.resultados.forEach(ia => {
    const original = reportes.find(r => r.id_reporte === ia.id_reporte);
    if (!original) return;

    const enriquecido = {
      ...original,
      ia_aula_detectada:    ia.aula_detectada    || null,
      ia_docente_detectado: ia.docente_detectado || null,
      ia_mobiliario:        ia.mobiliario_detectado || null,
      ia_sentimiento:       ia.sentimiento_label,
      ia_importancia:       ia.importancia,
    };

    // 1. POR AULA (NER - entidades LOC)
    if (ia.aula_detectada) {
      if (!porAula[ia.aula_detectada]) {
        porAula[ia.aula_detectada] = { aula: ia.aula_detectada, reportes: [] };
      }
      porAula[ia.aula_detectada].reportes.push(enriquecido);
    }

    // 2. POR DOCENTE (NER - entidades PER)
    if (ia.docente_detectado) {
      if (!porDocente[ia.docente_detectado]) {
        porDocente[ia.docente_detectado] = { docente: ia.docente_detectado, reportes: [] };
      }
      porDocente[ia.docente_detectado].reportes.push(enriquecido);
    }

    // 3. POR SENTIMIENTO (todos los reportes, siempre clasificados)
    const sentKey = ia.sentimiento_label || 'NEUTRAL';
    if (porSentimiento[sentKey]) {
      porSentimiento[sentKey].reportes.push(enriquecido);
    }
  });

  // Ordenar cada grupo: los de ALTA importancia primero
  const ordenImp = { ALTA: 0, MEDIA: 1, BAJA: 2 };
  const ordenar = arr => arr.sort((a, b) => (ordenImp[a.ia_importancia] ?? 1) - (ordenImp[b.ia_importancia] ?? 1));

  return {
    total_reportes:         reportes.length,
    total_procesados:       nlpResult.total_procesados,
    grupos_por_aula:        Object.values(porAula).map(g => ({ ...g, reportes: ordenar(g.reportes) })),
    grupos_por_docente:     Object.values(porDocente).map(g => ({ ...g, reportes: ordenar(g.reportes) })),
    grupos_por_sentimiento: ['NEGATIVO', 'NEUTRAL', 'POSITIVO']
      .map(k => porSentimiento[k])
      .filter(g => g.reportes.length > 0),
  };
};

module.exports = {
  getReportes,
  getReporteById,
  createReporte,
  updateReporte,
  deleteReporte,
  getClusteringReportes
};
