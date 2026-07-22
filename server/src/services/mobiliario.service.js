const mobiliarioCtrl = require('../controllers/mobiliario.controller');
const AppError = require('../utils/AppError');

const getMobiliario = async () => {
  return mobiliarioCtrl.findAll();
};

const getMobiliarioById = async (id) => {
  const mobiliario = await mobiliarioCtrl.findById(id);
  if (!mobiliario) {
    throw new AppError('Mobiliario no encontrado en el catálogo.', 404);
  }
  return mobiliario;
};

const createMobiliario = async ({ categoria, nombre, modelo, num_de_serie, stock_disponible }) => {
  if (!categoria || !nombre) {
    throw new AppError('La categoría y el nombre son requeridos.', 400);
  }

  if (num_de_serie) {
    const existente = await mobiliarioCtrl.findByNumSerie(num_de_serie);
    if (existente) {
      throw new AppError('El número de serie ingresado ya existe en otro mobiliario.', 409);
    }
  }

  return mobiliarioCtrl.create({
    categoria,
    nombre,
    modelo: modelo || null,
    num_de_serie: num_de_serie || null,
    stock_disponible: stock_disponible !== undefined ? Number(stock_disponible) : 0,
  });
};

const updateMobiliario = async (id, data) => {
  const existente = await mobiliarioCtrl.findById(id);
  if (!existente) {
    throw new AppError('Mobiliario no encontrado.', 404);
  }

  if (data.num_de_serie && data.num_de_serie !== existente.num_de_serie) {
    const conMismoSerie = await mobiliarioCtrl.findByNumSerie(data.num_de_serie);
    if (conMismoSerie) {
      throw new AppError('El número de serie ingresado ya está asignado a otro mobiliario.', 409);
    }
  }

  const dataToUpdate = {};
  if (data.categoria !== undefined) dataToUpdate.categoria = data.categoria;
  if (data.nombre !== undefined) dataToUpdate.nombre = data.nombre;
  if (data.modelo !== undefined) dataToUpdate.modelo = data.modelo;
  if (data.num_de_serie !== undefined) dataToUpdate.num_de_serie = data.num_de_serie;
  if (data.stock_disponible !== undefined) dataToUpdate.stock_disponible = Number(data.stock_disponible);

  if (Object.keys(dataToUpdate).length === 0) {
    throw new AppError('No se proporcionaron campos para actualizar.', 400);
  }

  return mobiliarioCtrl.update(id, dataToUpdate);
};

const deleteMobiliario = async (id) => {
  const existente = await mobiliarioCtrl.findById(id);
  if (!existente) {
    throw new AppError('Mobiliario no encontrado.', 404);
  }

  return mobiliarioCtrl.remove(id);
};

module.exports = { getMobiliario, getMobiliarioById, createMobiliario, updateMobiliario, deleteMobiliario };
