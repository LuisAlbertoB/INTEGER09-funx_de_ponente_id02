const misEspaciosCtrl = require('../controllers/misEspacios.controller');
const edificiosCtrl = require('../controllers/edificios.controller');
const AppError = require('../utils/AppError');

const createEspacio = async (userId, data) => {
  const { nombre_clave, id_edificio } = data;
  if (!nombre_clave || !id_edificio) {
    throw new AppError('nombre_clave y id_edificio son requeridos.', 400);
  }

  const edificio = await edificiosCtrl.findById(Number(id_edificio));
  if (!edificio) throw new AppError('Edificio no encontrado.', 404);

  return misEspaciosCtrl.createAulaPropia({
    nombre_clave,
    id_edificio: Number(id_edificio),
    id_owner: userId,
    estado: 1
  });
};

const getMisEspacios = async (userId) => {
  return misEspaciosCtrl.findMisAulas(userId);
};

const getMisSolicitudesRecibidas = async (userId) => {
  return misEspaciosCtrl.findSolicitudesHaciaMisAulas(userId);
};

const aprobarSolicitud = async (userId, idSolicitud) => {
  const solicitud = await misEspaciosCtrl.findSolicitudById(idSolicitud);
  
  if (!solicitud) throw new AppError('Solicitud no encontrada.', 404);
  if (solicitud.aula.id_owner !== userId) {
    throw new AppError('No eres el dueño del espacio solicitado.', 403);
  }
  if (solicitud.estado !== 'pendiente') {
    throw new AppError(`La solicitud ya ha sido procesada (${solicitud.estado}).`, 400);
  }

  // Aprobar
  const aprobada = await misEspaciosCtrl.updateEstadoSolicitud(idSolicitud, 'aprobada');
  
  // Rechazar colisiones
  await misEspaciosCtrl.rejectCollidingSolicitudes(
    solicitud.id_aula,
    solicitud.fecha_inicio,
    solicitud.fecha_final,
    idSolicitud
  );

  return aprobada;
};

const rechazarSolicitud = async (userId, idSolicitud) => {
  const solicitud = await misEspaciosCtrl.findSolicitudById(idSolicitud);
  
  if (!solicitud) throw new AppError('Solicitud no encontrada.', 404);
  if (solicitud.aula.id_owner !== userId) {
    throw new AppError('No eres el dueño del espacio solicitado.', 403);
  }
  if (solicitud.estado !== 'pendiente') {
    throw new AppError(`La solicitud ya ha sido procesada (${solicitud.estado}).`, 400);
  }

  return misEspaciosCtrl.updateEstadoSolicitud(idSolicitud, 'rechazada');
};

module.exports = {
  createEspacio,
  getMisEspacios,
  getMisSolicitudesRecibidas,
  aprobarSolicitud,
  rechazarSolicitud
};
