const ponenteCtrl = require('../controllers/ponente.controller');
const AppError = require('../utils/AppError');

const getMisConferencias = async (userId) => {
  return ponenteCtrl.findByPonente(userId);
};

const createConferencia = async (data, userId) => {
  if (!data.titulo || !data.id_actividad || !data.id_periodo) {
    throw new AppError('Faltan campos obligatorios: titulo, id_actividad, id_periodo.', 400);
  }

  return ponenteCtrl.create({
    titulo: data.titulo,
    descripcion: data.descripcion,
    tematica: data.tematica,
    nivel_academico_objetivo: data.nivel_academico_objetivo,
    duracion_estimada_min: data.duracion_estimada_min ? Number(data.duracion_estimada_min) : undefined,
    id_ponente: userId,
    id_actividad: Number(data.id_actividad),
    id_periodo: Number(data.id_periodo),
    id_aula_utilizada: data.id_aula_utilizada ? Number(data.id_aula_utilizada) : null,
  });
};

const updateConferencia = async (id, data, userId, userRol, isOwner) => {
  if (!isOwner && userRol !== 'admin') {
    throw new AppError('No tienes permiso para modificar esta conferencia.', 403);
  }

  return ponenteCtrl.update(id, {
    titulo: data.titulo,
    descripcion: data.descripcion,
    tematica: data.tematica,
    nivel_academico_objetivo: data.nivel_academico_objetivo,
    duracion_estimada_min: data.duracion_estimada_min ? Number(data.duracion_estimada_min) : undefined,
    id_aula_utilizada: data.id_aula_utilizada ? Number(data.id_aula_utilizada) : undefined,
  });
};

const deleteConferencia = async (id, isOwner, userRol) => {
  if (!isOwner && userRol !== 'admin') {
    throw new AppError('No tienes permiso para eliminar esta conferencia.', 403);
  }

  return ponenteCtrl.softDelete(id);
};

const uploadMaterial = async (conferenciaId, materialData, file, isOwner, userRol) => {
  if (!file) {
    throw new AppError('No se subió ningún archivo.', 400);
  }
  if (!materialData.titulo_material) {
    throw new AppError('titulo_material es requerido.', 400);
  }
  if (!isOwner && userRol !== 'admin') {
    throw new AppError('No tienes permiso para agregar material a esta conferencia.', 403);
  }

  const url_almacenamiento = `/uploads/materiales/${file.filename}`;

  return ponenteCtrl.createMaterial({
    titulo_material: materialData.titulo_material,
    tipo_archivo: materialData.tipo_archivo || 'otro',
    url_almacenamiento,
    tamanio_bytes: file.size,
    publico: materialData.publico === 'false' ? false : true,
    id_conferencia: conferenciaId,
  });
};

const getConferenciaOwner = async (id) => {
  const conferencia = await ponenteCtrl.findById(id);
  if (!conferencia) {
    throw new AppError('Conferencia no encontrada.', 404);
  }
  return conferencia.id_ponente;
};

module.exports = {
  getMisConferencias,
  createConferencia,
  updateConferencia,
  deleteConferencia,
  uploadMaterial,
  getConferenciaOwner
};
