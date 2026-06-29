const express = require('express');
const router = express.Router();
const misEspaciosService = require('../services/misEspacios.service');
const verifyToken = require('../middlewares/verifyToken');

router.use(verifyToken);

// GET /api/mis-espacios
router.get('/', async (req, res) => {
  try {
    const espacios = await misEspaciosService.getMisEspacios(req.userId);
    return res.status(200).json(espacios);
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// POST /api/mis-espacios
router.post('/', async (req, res) => {
  try {
    const espacio = await misEspaciosService.createEspacio(req.userId, req.body);
    return res.status(201).json({ message: 'Espacio publicado.', espacio });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// GET /api/mis-espacios/solicitudes
router.get('/solicitudes', async (req, res) => {
  try {
    const solicitudes = await misEspaciosService.getMisSolicitudesRecibidas(req.userId);
    return res.status(200).json(solicitudes);
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// PUT /api/mis-espacios/solicitudes/:id/aprobar
router.put('/solicitudes/:id/aprobar', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido' });
  try {
    const aprobada = await misEspaciosService.aprobarSolicitud(req.userId, id);
    return res.status(200).json({ message: 'Solicitud aprobada.', aprobada });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// PUT /api/mis-espacios/solicitudes/:id/rechazar
router.put('/solicitudes/:id/rechazar', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido' });
  try {
    const rechazada = await misEspaciosService.rechazarSolicitud(req.userId, id);
    return res.status(200).json({ message: 'Solicitud rechazada.', rechazada });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

module.exports = router;
