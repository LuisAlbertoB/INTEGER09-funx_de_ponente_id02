const prisma = require('../prismaClient');

const findAll = async () => {
  return prisma.catalogoInmobiliario.findMany({
    orderBy: [{ categoria: 'asc' }, { nombre: 'asc' }],
  });
};

const findById = async (id) => {
  return prisma.catalogoInmobiliario.findUnique({ where: { id_inmobiliario: id } });
};

const findByNumSerie = async (num_de_serie) => {
  return prisma.catalogoInmobiliario.findUnique({ where: { num_de_serie } });
};

const create = async (data) => {
  return prisma.catalogoInmobiliario.create({ data });
};

const update = async (id, data) => {
  return prisma.catalogoInmobiliario.update({
    where: { id_inmobiliario: id },
    data
  });
};

const remove = async (id) => {
  return prisma.catalogoInmobiliario.delete({
    where: { id_inmobiliario: id }
  });
};

module.exports = { findAll, findById, findByNumSerie, create, update, remove };
