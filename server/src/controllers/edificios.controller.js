const prisma = require('../prismaClient');

const findAll = async () => {
  return prisma.edificio.findMany({
    include: { aulas: true },
    orderBy: { nombre_clave: 'asc' },
  });
};

const findById = async (id) => {
  return prisma.edificio.findUnique({
    where: { id_edificio: id },
    include: { aulas: true }
  });
};

const create = async (data) => {
  return prisma.edificio.create({ data });
};

const update = async (id, data) => {
  return prisma.edificio.update({
    where: { id_edificio: id },
    data
  });
};

const softDelete = async (id) => {
  return prisma.edificio.update({
    where: { id_edificio: id },
    data: { estado: 0 }
  });
};

module.exports = { findAll, findById, create, update, softDelete };
