const express = require('express');
const router = express.Router();
const verifyToken = require('../middlewares/verifyToken');
const solicitudesInmobService = require('../services/solicitudesInmobiliario.service');

router.use(verifyToken);

// GET /api/solicitudes-inmobiliario
router.get('/', async (req, res) => {
  try {
    const solicitudes = await solicitudesInmobService.getSolicitudesInmobiliario(req.query);
    return res.status(200).json(solicitudes);
  } catch (error) {
    console.error('Error en getSolicitudesInmobiliario:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// POST /api/solicitudes-inmobiliario
router.post('/', async (req, res) => {
  try {
    const resultado = await solicitudesInmobService.createSolicitudInmobiliario(req.body, req.user.id_usuario);
    return res.status(201).json({ message: 'Solicitud de inmobiliario creada exitosamente.', solicitudInmobiliario: resultado });
  } catch (error) {
    console.error('Error en createSolicitudInmobiliario:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// PUT /api/solicitudes-inmobiliario/:id
router.put('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID de solicitud inválido.' });
  try {
    const actualizada = await solicitudesInmobService.updateSolicitudInmobiliario(id, req.body, req.user.id_usuario, req.user.rol);
    return res.status(200).json({ message: 'Solicitud de inmobiliario actualizada correctamente.', solicitudInmobiliario: actualizada });
  } catch (error) {
    console.error('Error en updateSolicitudInmobiliario:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

module.exports = router;
