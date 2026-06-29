const express = require('express');
const router = express.Router();
const reportesService = require('../services/reportes.service');
const verifyToken = require('../middlewares/verifyToken');

router.use(verifyToken);

// GET /api/reportes
router.get('/', async (req, res) => {
  try {
    const reportes = await reportesService.getReportes();
    return res.status(200).json(reportes);
  } catch (error) {
    console.error('Error en getReportes:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// GET /api/reportes/:id
router.get('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const reporte = await reportesService.getReporteById(id);
    return res.status(200).json(reporte);
  } catch (error) {
    console.error('Error en getReporteById:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// POST /api/reportes
router.post('/', async (req, res) => {
  try {
    const nuevoReporte = await reportesService.createReporte(req.userId, req.body);
    return res.status(201).json({ message: 'Reporte creado.', reporte: nuevoReporte });
  } catch (error) {
    console.error('Error en createReporte:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// PUT /api/reportes/:id
router.put('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const reporte = await reportesService.updateReporte(req.userId, req.userRole, id, req.body);
    return res.status(200).json({ message: 'Reporte actualizado.', reporte });
  } catch (error) {
    console.error('Error en updateReporte:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// DELETE /api/reportes/:id
router.delete('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    await reportesService.deleteReporte(req.userId, req.userRole, id);
    return res.status(200).json({ message: 'Reporte eliminado correctamente.' });
  } catch (error) {
    console.error('Error en deleteReporte:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

module.exports = router;
