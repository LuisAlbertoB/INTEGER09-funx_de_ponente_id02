const actividadesCtrl = require('../controllers/actividades.controller');
const AppError = require('../utils/AppError');

const getActividades = async () => {
  return actividadesCtrl.findAll();
};

const getActividadById = async (id) => {
  const actividad = await actividadesCtrl.findById(id);
  if (!actividad) {
    throw new AppError('Actividad no encontrada.', 404);
  }
  return actividad;
};

const createActividad = async ({ titulo_actividad, subtitulo_actividad, descripcion }) => {
  if (!titulo_actividad) {
    throw new AppError('El título de la actividad es requerido.', 400);
  }

  return actividadesCtrl.create({
    titulo_actividad,
    subtitulo_actividad: subtitulo_actividad || null,
    descripcion: descripcion || null,
  });
};

const updateActividad = async (id, data) => {
  const existente = await actividadesCtrl.findById(id);
  if (!existente) {
    throw new AppError('Actividad no encontrada.', 404);
  }

  const dataToUpdate = {};
  if (data.titulo_actividad !== undefined) dataToUpdate.titulo_actividad = data.titulo_actividad;
  if (data.subtitulo_actividad !== undefined) dataToUpdate.subtitulo_actividad = data.subtitulo_actividad;
  if (data.descripcion !== undefined) dataToUpdate.descripcion = data.descripcion;

  if (Object.keys(dataToUpdate).length === 0) {
    throw new AppError('No se proporcionaron campos para actualizar.', 400);
  }

  return actividadesCtrl.update(id, dataToUpdate);
};

const deleteActividad = async (id) => {
  const existente = await actividadesCtrl.findById(id);
  if (!existente) {
    throw new AppError('Actividad no encontrada.', 404);
  }

  return actividadesCtrl.remove(id);
};

module.exports = { getActividades, getActividadById, createActividad, updateActividad, deleteActividad };
