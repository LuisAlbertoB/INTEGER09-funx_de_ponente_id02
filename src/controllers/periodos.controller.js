const prisma = require('../prismaClient');

const findAll = async () => {
  return prisma.periodo.findMany({
    orderBy: { fecha_inicio: 'desc' },
  });
};

const findActive = async () => {
  return prisma.periodo.findFirst({
    where: { estado: 1 },
  });
};

const getActivePeriodId = async () => {
  const periodo = await prisma.periodo.findFirst({
    where: { estado: 1 },
    select: { id_periodo: true },
  });
  return periodo ? periodo.id_periodo : null;
};

const create = async (data, tx = prisma) => {
  return tx.periodo.create({ data });
};

const update = async (id, data, tx = prisma) => {
  return tx.periodo.update({
    where: { id_periodo: id },
    data,
  });
};

const deactivateAll = async (tx = prisma) => {
  return tx.periodo.updateMany({
    where: { estado: 1 },
    data: { estado: 0 },
  });
};

// Exponer prisma.$transaction para que los services puedan usarlo
const transaction = async (fn) => {
  return prisma.$transaction(fn);
};

module.exports = { findAll, findActive, getActivePeriodId, create, update, deactivateAll, transaction };
