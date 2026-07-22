const aulasCtrl = require('../controllers/aulas.controller');
const edificiosCtrl = require('../controllers/edificios.controller');
const AppError = require('../utils/AppError');

const getAulas = async () => {
  return aulasCtrl.findAll();
};

const getAulaById = async (id) => {
  const aula = await aulasCtrl.findById(id);
  if (!aula) {
    throw new AppError('Aula no encontrada.', 404);
  }
  return aula;
};

const createAula = async ({ nombre_clave, id_edificio }) => {
  if (!nombre_clave || !id_edificio) {
    throw new AppError('El nombre clave y el id_edificio son requeridos.', 400);
  }

  const edificio = await edificiosCtrl.findById(Number(id_edificio));
  if (!edificio) {
    throw new AppError('El edificio especificado no existe.', 404);
  }

  return aulasCtrl.create({ nombre_clave, id_edificio: Number(id_edificio), estado: 1 });
};

const updateAula = async (id, data) => {
  const existente = await aulasCtrl.findById(id);
  if (!existente) {
    throw new AppError('Aula no encontrada.', 404);
  }

  const dataToUpdate = {};
  if (data.nombre_clave !== undefined) dataToUpdate.nombre_clave = data.nombre_clave;
  if (data.estado !== undefined) {
    const estadoNum = Number(data.estado);
    if (![1, 0].includes(estadoNum)) throw new AppError('El estado debe ser 1 o 0.', 400);
    dataToUpdate.estado = estadoNum;
  }
  if (data.id_edificio !== undefined) {
    const edificio = await edificiosCtrl.findById(Number(data.id_edificio));
    if (!edificio) throw new AppError('El edificio especificado no existe.', 404);
    dataToUpdate.id_edificio = Number(data.id_edificio);
  }

  if (Object.keys(dataToUpdate).length === 0) {
    throw new AppError('No se proporcionaron campos para actualizar.', 400);
  }

  return aulasCtrl.update(id, dataToUpdate);
};

const deleteAula = async (id) => {
  const existente = await aulasCtrl.findById(id);
  if (!existente) {
    throw new AppError('Aula no encontrada.', 404);
  }

  return aulasCtrl.softDelete(id);
};

module.exports = { getAulas, getAulaById, createAula, updateAula, deleteAula };
