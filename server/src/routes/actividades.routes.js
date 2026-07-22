const express = require('express');
const router = express.Router();
const actividadesService = require('../services/actividades.service');
const verifyToken = require('../middlewares/verifyToken');
const verifyAdmin = require('../middlewares/verifyAdmin');

// Solo usuarios autenticados pueden ver el catálogo
router.use(verifyToken);

// GET /api/actividades
router.get('/', async (req, res) => {
  try {
    const actividades = await actividadesService.getActividades();
    return res.status(200).json(actividades);
  } catch (error) {
    console.error('Error en getActividades:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// GET /api/actividades/:id
router.get('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const actividad = await actividadesService.getActividadById(id);
    return res.status(200).json(actividad);
  } catch (error) {
    console.error('Error en getActividadById:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// POST /api/actividades - Solo admin
router.post('/', verifyAdmin, async (req, res) => {
  try {
    const nuevaActividad = await actividadesService.createActividad(req.body);
    return res.status(201).json({ message: 'Actividad creada.', actividad: nuevaActividad });
  } catch (error) {
    console.error('Error en createActividad:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// PUT /api/actividades/:id - Solo admin
router.put('/:id', verifyAdmin, async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const actividad = await actividadesService.updateActividad(id, req.body);
    return res.status(200).json({ message: 'Actividad actualizada.', actividad });
  } catch (error) {
    console.error('Error en updateActividad:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// DELETE /api/actividades/:id - Solo admin
router.delete('/:id', verifyAdmin, async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    await actividadesService.deleteActividad(id);
    return res.status(200).json({ message: 'Actividad eliminada correctamente.' });
  } catch (error) {
    console.error('Error en deleteActividad:', error);
    if (error.code === 'P2003') {
      return res.status(409).json({ message: 'No se puede eliminar esta actividad porque ya tiene conferencias o solicitudes vinculadas.' });
    }
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

module.exports = router;
