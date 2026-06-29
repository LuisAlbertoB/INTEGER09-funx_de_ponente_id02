const edificiosCtrl = require('../controllers/edificios.controller');
const AppError = require('../utils/AppError');

const getEdificios = async () => {
  return edificiosCtrl.findAll();
};

const getEdificioById = async (id) => {
  const edificio = await edificiosCtrl.findById(id);
  if (!edificio) {
    throw new AppError('Edificio no encontrado.', 404);
  }
  return edificio;
};

const createEdificio = async ({ nombre_clave }) => {
  if (!nombre_clave) {
    throw new AppError('El nombre o clave del edificio es requerido.', 400);
  }
  return edificiosCtrl.create({ nombre_clave, estado: 1 });
};

const updateEdificio = async (id, data) => {
  const existente = await edificiosCtrl.findById(id);
  if (!existente) {
    throw new AppError('Edificio no encontrado.', 404);
  }

  const dataToUpdate = {};
  if (data.nombre_clave !== undefined) dataToUpdate.nombre_clave = data.nombre_clave;
  if (data.estado !== undefined) {
    const estadoNum = Number(data.estado);
    if (![1, 0].includes(estadoNum)) throw new AppError('El estado debe ser 1 o 0.', 400);
    dataToUpdate.estado = estadoNum;
  }

  if (Object.keys(dataToUpdate).length === 0) {
    throw new AppError('No se proporcionaron campos para actualizar.', 400);
  }

  return edificiosCtrl.update(id, dataToUpdate);
};

const deleteEdificio = async (id) => {
  const existente = await edificiosCtrl.findById(id);
  if (!existente) {
    throw new AppError('Edificio no encontrado.', 404);
  }
  
  // Usamos softDelete para ocultar el edificio sin romper las aulas ni reportes vinculados
  return edificiosCtrl.softDelete(id);
};

module.exports = { getEdificios, getEdificioById, createEdificio, updateEdificio, deleteEdificio };
