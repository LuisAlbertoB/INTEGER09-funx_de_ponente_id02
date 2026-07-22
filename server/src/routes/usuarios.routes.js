const express = require('express');
const router = express.Router();
const verifyToken = require('../middlewares/verifyToken');
const verifyAdmin = require('../middlewares/verifyAdmin');
const usuariosService = require('../services/usuarios.service');

// Todas las rutas de usuarios requieren token + rol admin
router.use(verifyToken, verifyAdmin);

// GET /api/usuarios
router.get('/', async (req, res) => {
  try {
    const result = await usuariosService.getUsuarios(
      parseInt(req.query.page) || 1,
      parseInt(req.query.limit) || 10
    );
    return res.status(200).json(result);
  } catch (error) {
    console.error('Error en getUsuarios:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// POST /api/usuarios
router.post('/', async (req, res) => {
  const { nombre_completo, matricula, contrasena, rol } = req.body;
  if (!nombre_completo || !matricula || !contrasena || !rol) {
    return res.status(400).json({ message: 'Todos los campos son requeridos: nombre_completo, matricula, contrasena, rol.' });
  }
  try {
    const nuevoUsuario = await usuariosService.createUsuario(
      { nombre_completo, matricula, contrasena, rol },
      req.user.id_usuario
    );
    return res.status(201).json({ message: 'Usuario creado exitosamente.', usuario: nuevoUsuario });
  } catch (error) {
    console.error('Error en createUsuario:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// PUT /api/usuarios/:id/estado
router.put('/:id/estado', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID de usuario inválido.' });
  try {
    const usuarioActualizado = await usuariosService.updateEstadoUsuario(id, req.body.estado);
    return res.status(200).json({ message: 'Estado actualizado correctamente.', usuario: usuarioActualizado });
  } catch (error) {
    console.error('Error en updateEstadoUsuario:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// DELETE /api/usuarios/:id
router.delete('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID de usuario inválido.' });
  try {
    await usuariosService.deleteUsuario(id);
    return res.status(200).json({ message: 'Usuario eliminado correctamente.' });
  } catch (error) {
    console.error('Error en deleteUsuario:', error);
    // P2003 es el código de error de Prisma para violaciones de Foreign Key
    if (error.code === 'P2003') {
      return res.status(409).json({
        message: 'No se puede eliminar este usuario porque tiene solicitudes o registros asociados en el sistema. Te recomendamos desactivarlo (cambiar estado a 0) en lugar de eliminarlo.'
      });
    }
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

module.exports = router;
