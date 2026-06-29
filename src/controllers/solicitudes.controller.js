const prisma = require('../prismaClient');

const SOLICITUD_INCLUDES = {
  actividad: true,
  periodo: true,
  solicitante: {
    select: { id_usuario: true, nombre_completo: true, matricula: true },
  },
  aula: {
    include: {
      edificio: { select: { id_edificio: true, nombre_clave: true } },
    },
  },
  solicitudesInmobiliarioVinculadas: {
    include: {
      solicitudInmobiliario: {
        include: {
          inmobiliario: { select: { id_inmobiliario: true, nombre: true, categoria: true } },
        },
      },
    },
  },
};

const findAll = async (whereClause = {}) => {
  return prisma.solicitud.findMany({
    where: whereClause,
    include: SOLICITUD_INCLUDES,
    orderBy: { createdAt: 'desc' },
  });
};

const findById = async (id) => {
  return prisma.solicitud.findUnique({
    where: { id_solicitud: id },
  });
};

const findByIdFull = async (id, tx = prisma) => {
  return tx.solicitud.findUnique({
    where: { id_solicitud: id },
    include: SOLICITUD_INCLUDES,
  });
};

const create = async (data, tx = prisma) => {
  return tx.solicitud.create({ data });
};

const update = async (id, data) => {
  return prisma.solicitud.update({
    where: { id_solicitud: id },
    data,
    include: SOLICITUD_INCLUDES,
  });
};

const createPivote = async (id_solicitud, id_solicitud_inmobiliario, tx = prisma) => {
  return tx.solicitudHasSolicitudInmobiliario.create({
    data: { id_solicitud, id_solicitud_inmobiliario: Number(id_solicitud_inmobiliario) },
  });
};

const transaction = async (fn) => {
  return prisma.$transaction(fn);
};

module.exports = { findAll, findById, findByIdFull, create, update, createPivote, transaction };
