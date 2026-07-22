const eventosCtrl = require('../controllers/eventos.controller');
const aulasCtrl = require('../controllers/aulas.controller');
const periodosService = require('../services/periodos.service');
const nlpClient = require('../services/nlp.client');
const AppError = require('../utils/AppError');

const createEvento = async (userId, data) => {
  const { titulo, descripcion, tematica, nivel_academico_objetivo, id_actividad } = data;
  
  if (!titulo || !id_actividad) {
    throw new AppError('El título y id_actividad son requeridos.', 400);
  }

  const periodoId = await periodosService.getActivePeriod();

  const evento = await eventosCtrl.createEvento({
    titulo,
    descripcion: descripcion || null,
    tematica: tematica || null,
    nivel_academico_objetivo: nivel_academico_objetivo || 'ambos',
    id_ponente: userId,
    id_actividad: Number(id_actividad),
    id_periodo: periodoId,
    estado: 1
  });

  // ── NLP Indexación Semántica en segundo plano (Fire & Forget) ──
  nlpClient.indexarEvento(evento.id_conferencia, evento.titulo, evento.descripcion);

  return evento;
};

const listEventos = async (queryData) => {
  const { page, limit, estado, id_actividad, nivel_academico_objetivo, id_ponente } = queryData;
  const filters = {
    estado,
    id_actividad,
    nivel_academico_objetivo,
    id_ponente
  };
  return eventosCtrl.getEventos(filters, page || 1, limit || 10);
};

const getEventoById = async (id) => {
  const evento = await eventosCtrl.findEventoById(id);
  if (!evento) throw new AppError('El evento no existe.', 404);
  return evento;
};

const solicitarEspacio = async (userId, idEvento, idEspacio, data) => {
  const { fecha_inicio, fecha_final, motivo } = data;

  if (!fecha_inicio || !fecha_final) {
    throw new AppError('Las fechas de inicio y fin son obligatorias para solicitar espacio.', 400);
  }

  const evento = await eventosCtrl.findEventoById(idEvento);
  if (!evento) throw new AppError('El evento no existe.', 404);
  if (evento.id_ponente !== userId) throw new AppError('Solo el creador del evento puede solicitar espacios para él.', 403);

  const aula = await aulasCtrl.findById(idEspacio);
  if (!aula) throw new AppError('El espacio solicitado no existe.', 404);

  const periodoId = await periodosService.getActivePeriod();

  // Crea una solicitud tipo "normal" vinculada a la actividad del evento
  return eventosCtrl.createSolicitudEspacio({
    tipo_solicitud: 'normal',
    fecha_inicio: new Date(fecha_inicio),
    fecha_final: new Date(fecha_final),
    motivo: motivo || `Solicitud para evento: ${evento.titulo}`,
    estado: 'pendiente',
    id_user_solicitante: userId,
    id_aula: idEspacio,
    id_periodo: periodoId,
    id_actividad: evento.id_actividad
  });
};

const getForo = async (idEvento) => {
  const evento = await eventosCtrl.findEventoById(idEvento);
  if (!evento) throw new AppError('El evento no existe.', 404);
  return eventosCtrl.getComentariosForo(idEvento);
};

const postComentarioForo = async (userId, idEvento, data) => {
  const { mensaje, id_comentario_padre } = data;
  if (!mensaje) throw new AppError('El mensaje no puede estar vacío.', 400);

  const evento = await eventosCtrl.findEventoById(idEvento);
  if (!evento) throw new AppError('El evento no existe.', 404);

  return eventosCtrl.createComentario({
    mensaje,
    id_evento: idEvento,
    id_usuario: userId,
    id_comentario_padre: id_comentario_padre ? Number(id_comentario_padre) : null
  });
};

const submitEvaluacion = async (userId, idEvento, data) => {
  const { calificacion, porcentaje_satisfaccion, comentario_escrito } = data;

  if (calificacion === undefined || porcentaje_satisfaccion === undefined) {
    throw new AppError('Calificación y porcentaje de satisfacción son requeridos.', 400);
  }

  const evento = await eventosCtrl.findEventoById(idEvento);
  if (!evento) throw new AppError('El evento no existe.', 404);

  try {
    const evaluacion = await eventosCtrl.createEvaluacion({
      calificacion: Number(calificacion),
      porcentaje_satisfaccion: Number(porcentaje_satisfaccion),
      comentario_escrito: comentario_escrito || null,
      id_evento: idEvento,
      id_usuario: userId
    });

    // ── NLP en segundo plano (Fire & Forget) ──────────────────────────
    // Si el alumno dejó un comentario escrito, analizamos su sentimiento.
    if (comentario_escrito && comentario_escrito.trim().length >= 3) {
      nlpClient.evaluarSentimiento(comentario_escrito).then(resultado => {
        if (resultado) {
          console.log(`🎭 Evaluación Evento #${idEvento} → Sentimiento: ${resultado.label} (${resultado.estrellas}⭐, ${(resultado.confianza * 100).toFixed(1)}%)`);
        }
      });
    }

    return evaluacion;
  } catch (error) {
    if (error.code === 'P2002') {
      throw new AppError('Ya has evaluado este evento anteriormente.', 409);
    }
    throw error;
  }
};

const submitFeedbackAsistente = async (userId, idEvento, data) => {
  const {
    nivel_academico,
    especialidad,
    genero,
    duracion_interaccion_min,
    total_interacciones,
    tareas_completadas,
    porcentaje_aciertos,
    calificacion,
    participation_level,
    score_logistica,
    score_contenido,
    comentario_escrito
  } = data;

  const evento = await eventosCtrl.findEventoById(idEvento);
  if (!evento) throw new AppError('El evento no existe.', 404);

  try {
    const feedback = await eventosCtrl.createFeedbackAsistente({
      nivel_academico: nivel_academico || 'ambos',
      especialidad: especialidad || null,
      genero: genero || 'prefiero_no_decir',
      duracion_interaccion_min: Number(duracion_interaccion_min || 0),
      total_interacciones: Number(total_interacciones || 0),
      tareas_completadas: Number(tareas_completadas || 0),
      porcentaje_aciertos: Number(porcentaje_aciertos || 0),
      calificacion: Number(calificacion || 0),
      participation_level: participation_level || 'pasivo',
      score_logistica: Number(score_logistica || 3),
      score_contenido: Number(score_contenido || 3),
      comentario_escrito: comentario_escrito || null,
      id_conferencia: idEvento,
      id_usuario: userId
    });

    // ── NLP en segundo plano (Fire & Forget) ──────────────────────────
    if (comentario_escrito && comentario_escrito.trim().length >= 3) {
      nlpClient.evaluarSentimiento(comentario_escrito).then(resultado => {
        if (resultado) {
          console.log(`🎭 Feedback Evento #${idEvento} → Sentimiento: ${resultado.label} (${resultado.estrellas}⭐, ${(resultado.confianza * 100).toFixed(1)}%)`);
        }
      });
    }

    return feedback;
  } catch (error) {
    throw error;
  }
};

const getRecomendaciones = async (userId) => {
  // 1. Obtener historial del usuario
  const historyIds = await eventosCtrl.getHistorialUsuario(userId);
  if (historyIds.length === 0) {
    return []; // Sin historial no hay recomendaciones personalizadas
  }

  // 2. Pedir recomendaciones a la IA basadas en el historial
  const recomendados = await nlpClient.obtenerRecomendaciones(historyIds, 3);
  if (!recomendados || recomendados.length === 0) {
    return [];
  }

  // 3. Buscar los eventos reales en la DB
  const idsRecomendados = recomendados.map(r => r.id_evento);
  const eventos = await eventosCtrl.findEventosByIds(idsRecomendados);

  // Mapear con el score para ordenarlos
  const eventosConScore = eventos.map(evento => {
    const aiData = recomendados.find(r => r.id_evento === evento.id_conferencia);
    return { ...evento, ai_score: aiData.score };
  });

  return eventosConScore.sort((a, b) => b.ai_score - a.ai_score);
};

module.exports = {
  createEvento,
  listEventos,
  getEventoById,
  solicitarEspacio,
  getForo,
  postComentarioForo,
  submitEvaluacion,
  submitFeedbackAsistente,
  getRecomendaciones
};
