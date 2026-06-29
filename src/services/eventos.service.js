const eventosCtrl = require('../controllers/eventos.controller');
const aulasCtrl = require('../controllers/aulas.controller');
const periodosService = require('../services/periodos.service');
const AppError = require('../utils/AppError');

const createEvento = async (userId, data) => {
  const { titulo, descripcion, tematica, nivel_academico_objetivo, id_actividad } = data;
  
  if (!titulo || !id_actividad) {
    throw new AppError('El título y id_actividad son requeridos.', 400);
  }

  const periodoActivo = await periodosService.getActivePeriod();

  return eventosCtrl.createEvento({
    titulo,
    descripcion: descripcion || null,
    tematica: tematica || null,
    nivel_academico_objetivo: nivel_academico_objetivo || 'ambos',
    id_ponente: userId, // El event manager / ponente que lo crea
    id_actividad: Number(id_actividad),
    id_periodo: periodoActivo.id_periodo,
    estado: 1 // 1: Activo/Borrador
  });
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

  const periodoActivo = await periodosService.getActivePeriod();

  // Crea una solicitud tipo "normal" vinculada a la actividad del evento
  return eventosCtrl.createSolicitudEspacio({
    tipo_solicitud: 'normal',
    fecha_inicio: new Date(fecha_inicio),
    fecha_final: new Date(fecha_final),
    motivo: motivo || `Solicitud para evento: ${evento.titulo}`,
    estado: 'pendiente',
    id_user_solicitante: userId,
    id_aula: idEspacio,
    id_periodo: periodoActivo.id_periodo,
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
    const eval = await eventosCtrl.createEvaluacion({
      calificacion: Number(calificacion),
      porcentaje_satisfaccion: Number(porcentaje_satisfaccion),
      comentario_escrito: comentario_escrito || null,
      id_evento: idEvento,
      id_usuario: userId
    });
    return eval;
  } catch (error) {
    if (error.code === 'P2002') {
      throw new AppError('Ya has evaluado este evento anteriormente.', 409);
    }
    throw error;
  }
};

module.exports = {
  createEvento,
  solicitarEspacio,
  getForo,
  postComentarioForo,
  submitEvaluacion
};
