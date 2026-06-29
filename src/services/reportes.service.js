const reportesCtrl = require('../controllers/reportes.controller');
const aulasCtrl = require('../controllers/aulas.controller');
const mobiliarioCtrl = require('../controllers/mobiliario.controller');
const periodosService = require('../services/periodos.service');
const AppError = require('../utils/AppError');

const getReportes = async () => {
  return reportesCtrl.findAll();
};

const getReporteById = async (id) => {
  const reporte = await reportesCtrl.findById(id);
  if (!reporte) throw new AppError('Reporte no encontrado.', 404);
  return reporte;
};

const createReporte = async (userId, { titulo, descripcion, id_aula, id_mobiliario_afectado }) => {
  if (!titulo || !id_aula) {
    throw new AppError('El título y el id_aula son requeridos para crear un reporte.', 400);
  }

  // Validar aula
  const aula = await aulasCtrl.findById(Number(id_aula));
  if (!aula) throw new AppError('El aula especificada no existe.', 404);

  // Validar mobiliario si se envió
  if (id_mobiliario_afectado) {
    const mobiliario = await mobiliarioCtrl.findById(Number(id_mobiliario_afectado));
    if (!mobiliario) throw new AppError('El mobiliario especificado no existe.', 404);
  }

  // Obtener periodo activo automáticamente
  const periodoActivo = await periodosService.getActivePeriod();

  return reportesCtrl.create({
    titulo,
    descripcion: descripcion || null,
    id_user_reportante: userId,
    id_aula: Number(id_aula),
    id_mobiliario_afectado: id_mobiliario_afectado ? Number(id_mobiliario_afectado) : null,
    id_periodo: periodoActivo.id_periodo
  });
};

const updateReporte = async (userId, userRole, id, data) => {
  const reporte = await getReporteById(id);
  
  // Validar permisos: Solo el admin o el creador del reporte pueden actualizarlo
  if (userRole !== 'admin' && reporte.id_user_reportante !== userId) {
    throw new AppError('No tienes permisos para modificar este reporte.', 403);
  }

  const dataToUpdate = {};
  if (data.titulo !== undefined) dataToUpdate.titulo = data.titulo;
  if (data.descripcion !== undefined) dataToUpdate.descripcion = data.descripcion;
  
  if (data.id_aula !== undefined) {
    const aula = await aulasCtrl.findById(Number(data.id_aula));
    if (!aula) throw new AppError('El aula especificada no existe.', 404);
    dataToUpdate.id_aula = Number(data.id_aula);
  }

  if (data.id_mobiliario_afectado !== undefined) {
    if (data.id_mobiliario_afectado === null) {
      dataToUpdate.id_mobiliario_afectado = null;
    } else {
      const mobiliario = await mobiliarioCtrl.findById(Number(data.id_mobiliario_afectado));
      if (!mobiliario) throw new AppError('El mobiliario especificado no existe.', 404);
      dataToUpdate.id_mobiliario_afectado = Number(data.id_mobiliario_afectado);
    }
  }

  if (Object.keys(dataToUpdate).length === 0) {
    throw new AppError('No se proporcionaron campos para actualizar.', 400);
  }

  return reportesCtrl.update(id, dataToUpdate);
};

const deleteReporte = async (userId, userRole, id) => {
  const reporte = await getReporteById(id);
  
  // Validar permisos
  if (userRole !== 'admin' && reporte.id_user_reportante !== userId) {
    throw new AppError('No tienes permisos para eliminar este reporte.', 403);
  }

  return reportesCtrl.remove(id);
};

module.exports = { getReportes, getReporteById, createReporte, updateReporte, deleteReporte };
