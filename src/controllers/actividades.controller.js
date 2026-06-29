const prisma = require('../prismaClient');

const findAll = async () => {
  return prisma.actividad.findMany({
    orderBy: { titulo_actividad: 'asc' },
    select: {
      id_actividad: true,
      titulo_actividad: true,
      subtitulo_actividad: true,
      descripcion: true
    }
  });
};

const findById = async (id) => {
  return prisma.actividad.findUnique({
    where: { id_actividad: id }
  });
};

const create = async (data) => {
  return prisma.actividad.create({ data });
};

const update = async (id, data) => {
  return prisma.actividad.update({
    where: { id_actividad: id },
    data
  });
};

const remove = async (id) => {
  return prisma.actividad.delete({
    where: { id_actividad: id }
  });
};

module.exports = { findAll, findById, create, update, remove };
