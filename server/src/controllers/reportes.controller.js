const prisma = require('../prismaClient');

const findAll = async () => {
  return prisma.reporte.findMany({
    include: {
      reportante: { select: { id_usuario: true, nombre_completo: true } },
      aula: { select: { id_aula: true, nombre_clave: true } },
      mobiliario: { select: { id_inmobiliario: true, nombre: true } },
    },
    orderBy: { createdAt: 'desc' },
  });
};

const findById = async (id) => {
  return prisma.reporte.findUnique({
    where: { id_reporte: id },
    include: {
      reportante: { select: { id_usuario: true, nombre_completo: true } },
      aula: { select: { id_aula: true, nombre_clave: true } },
      mobiliario: { select: { id_inmobiliario: true, nombre: true } },
    }
  });
};

const create = async (data) => {
  return prisma.reporte.create({ data });
};

const update = async (id, data) => {
  return prisma.reporte.update({
    where: { id_reporte: id },
    data
  });
};

const remove = async (id) => {
  return prisma.reporte.delete({
    where: { id_reporte: id }
  });
};

module.exports = { findAll, findById, create, update, remove };
