const prisma = require('../prismaClient');

const findByPonente = async (userId) => {
  return prisma.conferencia.findMany({
    where: {
      id_ponente: userId,
      estado: 1
    },
    include: {
      actividad: true,
      aula: { select: { nombre_clave: true, edificio: { select: { nombre_clave: true } } } },
      periodo: true,
      materiales: true,
      registroEvento: true
    },
    orderBy: { createdAt: 'desc' }
  });
};

const findById = async (id) => {
  return prisma.conferencia.findUnique({
    where: { id_conferencia: id },
    select: { id_ponente: true }
  });
};

const create = async (data) => {
  return prisma.conferencia.create({ data });
};

const update = async (id, data) => {
  return prisma.conferencia.update({
    where: { id_conferencia: id },
    data
  });
};

const softDelete = async (id) => {
  return prisma.conferencia.update({
    where: { id_conferencia: id },
    data: { estado: 0 }
  });
};

const createMaterial = async (data) => {
  return prisma.materialDeApoyo.create({ data });
};

module.exports = { findByPonente, findById, create, update, softDelete, createMaterial };
