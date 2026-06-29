const usuariosCtrl = require('../controllers/usuarios.controller');
const jwt = require('jsonwebtoken');
const AppError = require('../utils/AppError');

const login = async (matricula, contrasena) => {
  const usuario = await usuariosCtrl.findByMatricula(matricula);

  if (!usuario) {
    throw new AppError('Usuario no encontrado.', 404);
  }

  if (usuario.estado === 0) {
    throw new AppError('Cuenta inactiva. Contacte al administrador.', 403);
  }

  const passwordValida = await usuariosCtrl.comparePassword(contrasena, usuario.contrasena);
  if (!passwordValida) {
    throw new AppError('Contraseña incorrecta.', 401);
  }

  const token = jwt.sign(
    {
      id_usuario: usuario.id_usuario,
      matricula: usuario.matricula,
      nombre_completo: usuario.nombre_completo,
      rol: usuario.rol,
    },
    process.env.JWT_SECRET,
    { expiresIn: '40m' }
  );

  return {
    token,
    usuario: {
      id_usuario: usuario.id_usuario,
      nombre_completo: usuario.nombre_completo,
      matricula: usuario.matricula,
      rol: usuario.rol,
    },
  };
};

module.exports = { login };
