const prisma = require('../prismaClient');

const findAll = async () => {
  return prisma.aula.findMany({
    include: {
      edificio: {
        select: { id_edificio: true, nombre_clave: true },
      },
    },
    orderBy: { nombre_clave: 'asc' },
  });
};

const findById = async (id) => {
  return prisma.aula.findUnique({ where: { id_aula: id } });
};

const create = async (data) => {
  return prisma.aula.create({ data });
};

const update = async (id, data) => {
  return prisma.aula.update({
    where: { id_aula: id },
    data
  });
};

const softDelete = async (id) => {
  return prisma.aula.update({
    where: { id_aula: id },
    data: { estado: 0 }
  });
};

module.exports = { findAll, findById, create, update, softDelete };
