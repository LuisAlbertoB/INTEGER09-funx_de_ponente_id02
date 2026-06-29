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

module.exports = {
  createEvento,
  findEventoById,
  createSolicitudEspacio,
  getComentariosForo,
  createComentario,
  createEvaluacion
};
