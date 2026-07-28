const usuariosCtrl = require('../controllers/usuarios.controller');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const AppError = require('../utils/AppError');
const prisma = require('../prismaClient');

const login = async (matricula, contrasena) => {
  const usuario = await usuariosCtrl.findByMatricula(matricula);

  if (!usuario) throw new AppError('Usuario no encontrado.', 404);
  if (usuario.estado === 0) throw new AppError('Cuenta inactiva. Contacte al administrador.', 403);

  const passwordValida = await usuariosCtrl.comparePassword(contrasena, usuario.contrasena);
  if (!passwordValida) throw new AppError('Contraseña incorrecta.', 401);

  const token = jwt.sign(
    { id_usuario: usuario.id_usuario, matricula: usuario.matricula, nombre_completo: usuario.nombre_completo, rol: usuario.rol },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );

  return {
    token,
    usuario: { id_usuario: usuario.id_usuario, nombre_completo: usuario.nombre_completo, matricula: usuario.matricula, rol: usuario.rol },
  };
};

const updatePerfil = async (id_usuario, nombre_completo) => {
  return prisma.usuario.update({
    where: { id_usuario },
    data: { nombre_completo },
    select: { id_usuario: true, nombre_completo: true, matricula: true, rol: true },
  });
};

const changePassword = async (id_usuario, contrasena_actual, contrasena_nueva) => {
  const usuario = await prisma.usuario.findUnique({ where: { id_usuario } });
  if (!usuario) throw new AppError('Usuario no encontrado.', 404);

  const valida = await bcrypt.compare(contrasena_actual, usuario.contrasena);
  if (!valida) throw new AppError('La contraseña actual es incorrecta.', 401);

  const hash = await bcrypt.hash(contrasena_nueva, 10);
  await prisma.usuario.update({ where: { id_usuario }, data: { contrasena: hash } });
};

module.exports = { login, updatePerfil, changePassword };
