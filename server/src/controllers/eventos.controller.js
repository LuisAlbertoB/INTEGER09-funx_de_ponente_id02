const prisma = require('../prismaClient');

const createEvento = async (data) => {
  return prisma.conferencia.create({ data });
};

const findEventoById = async (id) => {
  return prisma.conferencia.findUnique({
    where: { id_conferencia: id },
    include: {
      aula: true,
      periodo: true
    }
  });
};

const getEventos = async (filters, page = 1, limit = 10) => {
  const skip = (page - 1) * limit;
  const where = {};

  if (filters.estado !== undefined) {
    where.estado = Number(filters.estado);
  }
  if (filters.id_actividad) {
    where.id_actividad = Number(filters.id_actividad);
  }
  if (filters.nivel_academico_objetivo) {
    where.nivel_academico_objetivo = filters.nivel_academico_objetivo;
  }
  if (filters.id_ponente) {
    where.id_ponente = Number(filters.id_ponente);
  }

  const [eventos, total] = await Promise.all([
    prisma.conferencia.findMany({
      where,
      skip,
      take: Number(limit),
      include: {
        ponente: { select: { nombre_completo: true } },
        actividad: { select: { titulo_actividad: true } },
        aula: { select: { nombre_clave: true } }
      },
      orderBy: { createdAt: 'desc' }
    }),
    prisma.conferencia.count({ where })
  ]);

  return { eventos, total, page: Number(page), limit: Number(limit) };
};

const createSolicitudEspacio = async (data) => {
  return prisma.solicitud.create({ data });
};

const getComentariosForo = async (id_evento) => {
  // Solo devolvemos los de primer nivel (padre = null), 
  // y con sus respuestas anidadas (hijos)
  return prisma.comentarioForo.findMany({
    where: { 
      id_evento,
      id_comentario_padre: null
    },
    include: {
      usuario: { select: { nombre_completo: true } },
      respuestas: {
        include: {
          usuario: { select: { nombre_completo: true } }
        },
        orderBy: { createdAt: 'asc' }
      }
    },
    orderBy: { createdAt: 'desc' }
  });
};

const createComentario = async (data) => {
  return prisma.comentarioForo.create({ data });
};

const createEvaluacion = async (data) => {
  return prisma.evaluacionEvento.create({ data });
};

const createFeedbackAsistente = async (data) => {
  return prisma.feedbackAsistente.create({ data });
};

const getHistorialUsuario = async (userId) => {
  // Obtiene los IDs de los eventos que el usuario ha evaluado
  const evaluaciones = await prisma.evaluacionEvento.findMany({
    where: { id_usuario: userId },
    select: { id_evento: true },
    orderBy: { createdAt: 'desc' },
    take: 10 // Considerar los últimos 10 eventos
  });
  return evaluaciones.map(e => e.id_evento);
};

const findEventosByIds = async (ids) => {
  return prisma.conferencia.findMany({
    where: { id_conferencia: { in: ids } },
    include: {
      ponente: { select: { nombre_completo: true } },
      actividad: { select: { titulo_actividad: true } }
    }
  });
};

const inscribirse = async (userId, idConferencia) => {
  return prisma.inscripcion.create({
    data: { id_usuario: userId, id_conferencia: idConferencia },
  });
};

const desinscribirse = async (userId, idConferencia) => {
  return prisma.inscripcion.delete({
    where: {
      id_usuario_id_conferencia: { id_usuario: userId, id_conferencia: idConferencia },
    },
  });
};

const getMisInscripciones = async (userId) => {
  return prisma.inscripcion.findMany({
    where: { id_usuario: userId },
    include: {
      conferencia: {
        include: {
          ponente: { select: { nombre_completo: true } },
          actividad: { select: { titulo_actividad: true } },
        },
      },
    },
    orderBy: { createdAt: 'desc' },
  });
};

const deleteEvento = async (id) => {
  return prisma.conferencia.delete({ where: { id_conferencia: id } });
};

const updateEvento = async (id, data) => {
  return prisma.conferencia.update({
    where: { id_conferencia: id },
    data,
  });
};

const getInscripcionesByEvento = async (idConferencia) => {
  return prisma.inscripcion.findMany({
    where: { id_conferencia: idConferencia },
    include: {
      usuario: { select: { nombre_completo: true, matricula: true } },
    },
    orderBy: { createdAt: 'desc' },
  });
};

module.exports = {
  createEvento,
  findEventoById,
  getEventos,
  createSolicitudEspacio,
  getComentariosForo,
  createComentario,
  createEvaluacion,
  createFeedbackAsistente,
  getHistorialUsuario,
  findEventosByIds,
  inscribirse,
  desinscribirse,
  getMisInscripciones,
  deleteEvento,
  updateEvento,
  getInscripcionesByEvento,
};
