const periodosCtrl = require('../controllers/periodos.controller');
const AppError = require('../utils/AppError');

const getActivePeriod = async () => {
  const id = await periodosCtrl.getActivePeriodId();
  if (!id) {
    throw new AppError('No hay un periodo escolar activo configurado en el sistema.', 404);
  }
  return id;
};

const getPeriodos = async () => {
  return periodosCtrl.findAll();
};

const getActivePeriodDetails = async () => {
  const periodo = await periodosCtrl.findActive();
  if (!periodo) {
    throw new AppError('No hay periodo escolar activo.', 404);
  }
  return periodo;
};

const createPeriodo = async ({ nombre_clave, fecha_inicio, fecha_final, estado }) => {
  if (!nombre_clave || !fecha_inicio || !fecha_final) {
    throw new AppError('Faltan campos obligatorios.', 400);
  }

  const estadoNumerico = Number(estado);
  const isActivo = estadoNumerico === 1;

  const nuevoPeriodo = await periodosCtrl.transaction(async (tx) => {
    if (isActivo) {
      await periodosCtrl.deactivateAll(tx);
    }

    return periodosCtrl.create({
      nombre_clave,
      fecha_inicio: new Date(fecha_inicio),
      fecha_final: new Date(fecha_final),
      estado: isActivo ? 1 : 0,
    }, tx);
  });

  return nuevoPeriodo;
};

const updatePeriodo = async (id, { nombre_clave, fecha_inicio, fecha_final, estado }) => {
  const dataToUpdate = {};
  if (nombre_clave) dataToUpdate.nombre_clave = nombre_clave;
  if (fecha_inicio) dataToUpdate.fecha_inicio = new Date(fecha_inicio);
  if (fecha_final) dataToUpdate.fecha_final = new Date(fecha_final);

  if (estado !== undefined) {
    const estadoNumerico = Number(estado);
    if (![1, 0].includes(estadoNumerico)) {
      throw new AppError('Estado inválido. Use 1 o 0.', 400);
    }
    dataToUpdate.estado = estadoNumerico;
  }

  const periodoActualizado = await periodosCtrl.transaction(async (tx) => {
    if (dataToUpdate.estado === 1) {
      await periodosCtrl.deactivateAll(tx);
    }

    return periodosCtrl.update(id, dataToUpdate, tx);
  });

  return periodoActualizado;
};

module.exports = { getActivePeriod, getPeriodos, getActivePeriodDetails, createPeriodo, updatePeriodo };
