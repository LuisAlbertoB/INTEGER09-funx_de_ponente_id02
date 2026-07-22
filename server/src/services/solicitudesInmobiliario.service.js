const solicitudesInmobCtrl = require('../controllers/solicitudesInmobiliario.controller');
const mobiliarioCtrl = require('../controllers/mobiliario.controller');
const periodosService = require('./periodos.service');
const AppError = require('../utils/AppError');

const getSolicitudesInmobiliario = async (filtros) => {
  const whereClause = {};
  if (filtros.periodo) {
    whereClause.id_periodo = Number(filtros.periodo);
  }
  return solicitudesInmobCtrl.findAll(whereClause);
};

const createSolicitudInmobiliario = async (data, userId) => {
  if (!data.id_inmobiliario_solicitado || !data.cantidad_solicitada || !data.fecha_inicio || !data.fecha_fin) {
    throw new AppError('Campos requeridos: id_inmobiliario_solicitado, cantidad_solicitada, fecha_inicio, fecha_fin.', 400);
  }

  if (data.cantidad_solicitada < 1) {
    throw new AppError('La cantidad solicitada debe ser al menos 1.', 400);
  }

  // Verificar que el inmobiliario exista
  const inmobiliario = await mobiliarioCtrl.findById(Number(data.id_inmobiliario_solicitado));
  if (!inmobiliario) {
    throw new AppError('El inmobiliario solicitado no existe en el catálogo.', 404);
  }

  // Verificar stock disponible
  if (inmobiliario.stock_disponible < data.cantidad_solicitada) {
    throw new AppError(`Stock insuficiente. Disponible: ${inmobiliario.stock_disponible}, solicitado: ${data.cantidad_solicitada}.`, 400);
  }

  const id_periodo = await periodosService.getActivePeriod();

  return solicitudesInmobCtrl.create({
    id_inmobiliario_solicitado: Number(data.id_inmobiliario_solicitado),
    cantidad_solicitada: Number(data.cantidad_solicitada),
    fecha_inicio: new Date(data.fecha_inicio),
    fecha_fin: new Date(data.fecha_fin),
    id_user_solicitante: userId,
    id_periodo,
  });
};

const updateSolicitudInmobiliario = async (id, data, userId, userRol) => {
  const existente = await solicitudesInmobCtrl.findById(id);
  if (!existente) {
    throw new AppError('Solicitud de inmobiliario no encontrada.', 404);
  }

  // Solo el solicitante o un admin/coordinador pueden actualizar
  if (existente.id_user_solicitante !== userId && !['admin', 'coordinador'].includes(userRol)) {
    throw new AppError('No tienes permiso para modificar esta solicitud.', 403);
  }

  const dataToUpdate = {};
  if (data.cantidad_solicitada !== undefined) dataToUpdate.cantidad_solicitada = Number(data.cantidad_solicitada);
  if (data.estado !== undefined) {
    if (!['pendiente', 'aprobada', 'rechazada'].includes(data.estado)) {
      throw new AppError('Estado debe ser: pendiente, aprobada o rechazada.', 400);
    }
    dataToUpdate.estado = data.estado;
  }
  if (data.fecha_inicio !== undefined) dataToUpdate.fecha_inicio = new Date(data.fecha_inicio);
  if (data.fecha_fin !== undefined) dataToUpdate.fecha_fin = new Date(data.fecha_fin);

  if (Object.keys(dataToUpdate).length === 0) {
    throw new AppError('No se proporcionaron campos para actualizar.', 400);
  }

  return solicitudesInmobCtrl.update(id, dataToUpdate);
};

module.exports = { getSolicitudesInmobiliario, createSolicitudInmobiliario, updateSolicitudInmobiliario };
