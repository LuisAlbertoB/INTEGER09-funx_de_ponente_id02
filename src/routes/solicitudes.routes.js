const express = require('express');
const router = express.Router();
const verifyToken = require('../middlewares/verifyToken');
const solicitudesService = require('../services/solicitudes.service');

// Todas las rutas requieren token (admin o docente)
router.use(verifyToken);

// GET /api/solicitudes
router.get('/', async (req, res) => {
  try {
    const solicitudes = await solicitudesService.getSolicitudes(req.query);
    return res.status(200).json(solicitudes);
  } catch (error) {
    console.error('Error en getSolicitudes:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// POST /api/solicitudes
router.post('/', async (req, res) => {
  try {
    const resultado = await solicitudesService.createSolicitud(req.body, req.user.id_usuario);
    return res.status(201).json({ message: 'Solicitud creada exitosamente.', solicitud: resultado });
  } catch (error) {
    console.error('Error en createSolicitud:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// PUT /api/solicitudes/:id
router.put('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID de solicitud inválido.' });
  try {
    const actualizada = await solicitudesService.updateSolicitud(id, req.body, req.user.id_usuario, req.user.rol);
    return res.status(200).json({ message: 'Solicitud actualizada correctamente.', solicitud: actualizada });
  } catch (error) {
    console.error('Error en updateSolicitud:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

module.exports = router;
