const solicitudesCtrl = require('../controllers/solicitudes.controller');
const solicitudesInmobCtrl = require('../controllers/solicitudesInmobiliario.controller');
const aulasCtrl = require('../controllers/aulas.controller');
const periodosService = require('./periodos.service');
const AppError = require('../utils/AppError');
const prisma = require('../prismaClient');

const getSolicitudes = async (filtros) => {
  const whereClause = {};
  if (filtros.periodo) {
    whereClause.id_periodo = Number(filtros.periodo);
  }
  return solicitudesCtrl.findAll(whereClause);
};

const createSolicitud = async (data, userId) => {
  if (!data.fecha_inicio || !data.fecha_final || !data.motivo || !data.id_aula) {
    throw new AppError('Campos requeridos: fecha_inicio, fecha_final, motivo, id_aula.', 400);
  }

  const id_periodo = await periodosService.getActivePeriod();

  const aula = await aulasCtrl.findById(Number(data.id_aula));
  if (!aula) {
    throw new AppError('El aula especificada no existe.', 404);
  }

  const resultado = await prisma.$transaction(async (tx) => {
    // Determinar ID de Actividad
    let final_id_actividad = null;
    if (data.tipo_solicitud === 'normal') {
      if (!data.id_actividad) throw new AppError('Se requiere seleccionar una actividad oficial para solicitudes normales.', 400);
      final_id_actividad = Number(data.id_actividad);
    } else {
      if (!data.titulo_actividad) throw new AppError('Se requiere un título para la nueva actividad especial.', 400);
      const actividad = await tx.actividad.create({
        data: {
          titulo_actividad: data.titulo_actividad,
          subtitulo_actividad: data.subtitulo_actividad || null,
          descripcion: data.descripcion_actividad || null,
        }
      });
      final_id_actividad = actividad.id_actividad;
    }

    // Crear la Solicitud
    const solicitud = await solicitudesCtrl.create({
      tipo_solicitud: data.tipo_solicitud || 'normal',
      fecha_inicio: new Date(data.fecha_inicio),
      fecha_final: new Date(data.fecha_final),
      motivo: data.motivo,
      id_user_solicitante: userId,
      id_aula: Number(data.id_aula),
      id_periodo,
      id_actividad: final_id_actividad,
    }, tx);

    // Vincular solicitudes de inmobiliario
    if (data.solicitudes_inmobiliario_ids && data.solicitudes_inmobiliario_ids.length > 0) {
      const solicitudesInmob = await solicitudesInmobCtrl.findMany(data.solicitudes_inmobiliario_ids, tx);

      if (solicitudesInmob.length !== data.solicitudes_inmobiliario_ids.length) {
        throw new AppError('Una o más solicitudes de inmobiliario no fueron encontradas.', 400);
      }

      for (const idSolInmob of data.solicitudes_inmobiliario_ids) {
        await solicitudesCtrl.createPivote(solicitud.id_solicitud, idSolInmob, tx);
      }
    }

    // Recuperar solicitud completa
    return solicitudesCtrl.findByIdFull(solicitud.id_solicitud, tx);
  });

  return resultado;
};

const updateSolicitud = async (id, data, userId, userRol) => {
  const existente = await solicitudesCtrl.findById(id);
  if (!existente) {
    throw new AppError('Solicitud no encontrada.', 404);
  }

  // Solo el solicitante o un admin/coordinador pueden actualizar
  if (existente.id_user_solicitante !== userId && !['admin', 'coordinador'].includes(userRol)) {
    throw new AppError('No tienes permiso para modificar esta solicitud.', 403);
  }

  const dataToUpdate = {};
  if (data.tipo_solicitud !== undefined) {
    if (!['normal', 'especial'].includes(data.tipo_solicitud)) {
      throw new AppError('tipo_solicitud debe ser: normal o especial.', 400);
    }
    dataToUpdate.tipo_solicitud = data.tipo_solicitud;
  }
  if (data.fecha_inicio !== undefined) dataToUpdate.fecha_inicio = new Date(data.fecha_inicio);
  if (data.fecha_final !== undefined) dataToUpdate.fecha_final = new Date(data.fecha_final);
  if (data.motivo !== undefined) dataToUpdate.motivo = data.motivo;
  if (data.id_aula !== undefined) dataToUpdate.id_aula = Number(data.id_aula);
  if (data.estado !== undefined) {
    if (!['pendiente', 'aprobada', 'rechazada'].includes(data.estado)) {
      throw new AppError('Estado debe ser: pendiente, aprobada o rechazada.', 400);
    }
    dataToUpdate.estado = data.estado;
  }

  if (Object.keys(dataToUpdate).length === 0) {
    throw new AppError('No se proporcionaron campos para actualizar.', 400);
  }

  return solicitudesCtrl.update(id, dataToUpdate);
};

module.exports = { getSolicitudes, createSolicitud, updateSolicitud };
