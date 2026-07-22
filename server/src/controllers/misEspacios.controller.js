const prisma = require('../prismaClient');

const createAulaPropia = async (data) => {
  return prisma.aula.create({ data });
};

const findMisAulas = async (userId) => {
  return prisma.aula.findMany({
    where: { id_owner: userId, estado: 1 },
    include: { edificio: { select: { nombre_clave: true } } }
  });
};

const updateAulaPropia = async (id, userId, data) => {
  return prisma.aula.update({
    where: { id_aula: id },
    data
  });
};

const findSolicitudesHaciaMisAulas = async (userId) => {
  return prisma.solicitud.findMany({
    where: {
      aula: {
        id_owner: userId
      },
      estado: 'pendiente' // Solo ver pendientes por defecto
    },
    include: {
      solicitante: { select: { nombre_completo: true } },
      aula: { select: { nombre_clave: true } },
      actividad: true
    },
    orderBy: { createdAt: 'desc' }
  });
};

const findSolicitudById = async (id) => {
  return prisma.solicitud.findUnique({
    where: { id_solicitud: id },
    include: { aula: true }
  });
};

const updateEstadoSolicitud = async (id, estado) => {
  return prisma.solicitud.update({
    where: { id_solicitud: id },
    data: { estado }
  });
};

const rejectCollidingSolicitudes = async (id_aula, fecha_inicio, fecha_final, id_aprobada) => {
  // Rechazar solicitudes empalmadas en el mismo espacio y fechas
  return prisma.solicitud.updateMany({
    where: {
      id_aula,
      id_solicitud: { not: id_aprobada },
      estado: 'pendiente',
      OR: [
        {
          fecha_inicio: { lte: fecha_final },
          fecha_final: { gte: fecha_inicio }
        }
      ]
    },
    data: { estado: 'rechazada' }
  });
};

module.exports = {
  createAulaPropia,
  findMisAulas,
  updateAulaPropia,
  findSolicitudesHaciaMisAulas,
  findSolicitudById,
  updateEstadoSolicitud,
  rejectCollidingSolicitudes
};
