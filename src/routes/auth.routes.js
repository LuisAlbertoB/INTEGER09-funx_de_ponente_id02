const express = require('express');
const router = express.Router();
const authService = require('../services/auth.service');

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
    console.error('Error en login:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

module.exports = router;
