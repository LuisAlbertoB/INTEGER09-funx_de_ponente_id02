const express = require('express');
const router = express.Router();
const authService = require('../services/auth.service');
const verifyToken = require('../middlewares/verifyToken');

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { matricula, contrasena } = req.body;
  if (!matricula || !contrasena) {
    return res.status(400).json({ message: 'Matrícula y contraseña son requeridos.' });
  }
  try {
    const result = await authService.login(matricula, contrasena);
    return res.status(200).json({ message: 'Login exitoso.', ...result });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// PUT /api/auth/perfil — actualizar nombre propio
router.put('/perfil', verifyToken, async (req, res) => {
  const { nombre_completo } = req.body;
  if (!nombre_completo || !nombre_completo.trim()) {
    return res.status(400).json({ message: 'El nombre no puede estar vacío.' });
  }
  try {
    const usuario = await authService.updatePerfil(req.user.id_usuario, nombre_completo.trim());
    return res.status(200).json({ message: 'Perfil actualizado.', usuario });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno.' });
  }
});

// PUT /api/auth/password — cambiar contraseña propia
router.put('/password', verifyToken, async (req, res) => {
  const { contrasena_actual, contrasena_nueva } = req.body;
  if (!contrasena_actual || !contrasena_nueva) {
    return res.status(400).json({ message: 'Contraseña actual y nueva son requeridas.' });
  }
  if (contrasena_nueva.length < 6) {
    return res.status(400).json({ message: 'La nueva contraseña debe tener al menos 6 caracteres.' });
  }
  try {
    await authService.changePassword(req.user.id_usuario, contrasena_actual, contrasena_nueva);
    return res.status(200).json({ message: 'Contraseña actualizada correctamente.' });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno.' });
  }
});

module.exports = router;
