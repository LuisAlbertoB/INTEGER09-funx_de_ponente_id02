const usuariosCtrl = require('../controllers/usuarios.controller');
const AppError = require('../utils/AppError');

const ROLES_VALIDOS = ['admin', 'ponente', 'coordinador', 'participante', 'asistente', 'usuario_general'];

const getUsuarios = async (page, limit) => {
  const skip = (page - 1) * limit;
  const [usuarios, total] = await usuariosCtrl.findAll(skip, limit);
  return {
    data: usuarios,
    pagination: {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit)
    }
  };
};

const createUsuario = async ({ nombre_completo, matricula, contrasena, rol }, creatorId) => {
  if (!ROLES_VALIDOS.includes(rol)) {
    throw new AppError(`El rol debe ser uno de: ${ROLES_VALIDOS.join(', ')}.`, 400);
  }

  const existente = await usuariosCtrl.findByMatricula(matricula);
  if (existente) {
    throw new AppError(`La matrícula ${matricula} ya está registrada.`, 409);
  }

  return usuariosCtrl.create({ nombre_completo, matricula, contrasena, rol, id_user_creator: creatorId });
};

const updateEstadoUsuario = async (id, estado) => {
  if (![1, 0].includes(estado)) {
    throw new AppError('El estado debe ser 1 (activo) o 0 (inactivo).', 400);
  }

  const usuario = await usuariosCtrl.findById(id);
  if (!usuario) {
    throw new AppError('Usuario no encontrado.', 404);
  }

  // Evitar alterar el estado del Admin Master
  if (usuario.matricula === '000000') {
    throw new AppError('No se puede modificar el estado del Administrador Principal.', 403);
  }

  return usuariosCtrl.updateEstado(id, estado);
};

const deleteUsuario = async (id) => {
  const usuario = await usuariosCtrl.findById(id);
  if (!usuario) {
    throw new AppError('Usuario no encontrado.', 404);
  }

  // Evitar eliminar al admin master
  if (usuario.matricula === '000000') {
    throw new AppError('No se puede eliminar al Administrador Principal.', 403);
  }

  return usuariosCtrl.remove(id);
};

module.exports = { getUsuarios, createUsuario, updateEstadoUsuario, deleteUsuario };
