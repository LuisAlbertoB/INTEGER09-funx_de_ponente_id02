const prisma = require('../prismaClient');

const findAll = async (whereClause = {}) => {
  return prisma.solicitudInmobiliario.findMany({
    where: whereClause,
    include: {
      periodo: true,
      solicitante: {
        select: { id_usuario: true, nombre_completo: true, matricula: true },
      },
      inmobiliario: {
        select: { id_inmobiliario: true, nombre: true, categoria: true, modelo: true },
      },
    },
    orderBy: { createdAt: 'desc' },
  });
};

const findById = async (id) => {
  return prisma.solicitudInmobiliario.findUnique({
    where: { id_solicitud_inmobiliario: id },
  });
};

const findMany = async (ids, tx = prisma) => {
  return tx.solicitudInmobiliario.findMany({
    where: { id_solicitud_inmobiliario: { in: ids.map(Number) } },
  });
};

const create = async (data) => {
  return prisma.solicitudInmobiliario.create({
    data,
    include: {
      inmobiliario: {
        select: { id_inmobiliario: true, nombre: true, categoria: true },
      },
    },
  });
};

const update = async (id, data) => {
  return prisma.solicitudInmobiliario.update({
    where: { id_solicitud_inmobiliario: id },
    data,
    include: {
      inmobiliario: {
        select: { id_inmobiliario: true, nombre: true, categoria: true },
      },
    },
  });
};

module.exports = { findAll, findById, findMany, create, update };
