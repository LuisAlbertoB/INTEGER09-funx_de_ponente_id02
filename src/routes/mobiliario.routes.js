const express = require('express');
const router = express.Router();
const mobiliarioService = require('../services/mobiliario.service');
const verifyToken = require('../middlewares/verifyToken');
const verifyAdmin = require('../middlewares/verifyAdmin');

router.use(verifyToken);

// GET /api/mobiliario
router.get('/', async (req, res) => {
  try {
    const catalogo = await mobiliarioService.getMobiliario();
    return res.status(200).json(catalogo);
  } catch (error) {
    console.error('Error en getMobiliario:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// GET /api/mobiliario/:id
router.get('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const mobiliario = await mobiliarioService.getMobiliarioById(id);
    return res.status(200).json(mobiliario);
  } catch (error) {
    console.error('Error en getMobiliarioById:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// POST /api/mobiliario - Solo admin
router.post('/', verifyAdmin, async (req, res) => {
  try {
    const nuevoMobiliario = await mobiliarioService.createMobiliario(req.body);
    return res.status(201).json({ message: 'Mobiliario registrado en el catálogo.', mobiliario: nuevoMobiliario });
  } catch (error) {
    console.error('Error en createMobiliario:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// PUT /api/mobiliario/:id - Solo admin
router.put('/:id', verifyAdmin, async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const mobiliario = await mobiliarioService.updateMobiliario(id, req.body);
    return res.status(200).json({ message: 'Mobiliario actualizado.', mobiliario });
  } catch (error) {
    console.error('Error en updateMobiliario:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// DELETE /api/mobiliario/:id - Solo admin
router.delete('/:id', verifyAdmin, async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    await mobiliarioService.deleteMobiliario(id);
    return res.status(200).json({ message: 'Mobiliario eliminado correctamente.' });
  } catch (error) {
    console.error('Error en deleteMobiliario:', error);
    if (error.code === 'P2003') {
      return res.status(409).json({ message: 'No se puede eliminar este mobiliario porque está asignado a un aula, reporte o solicitud.' });
    }
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

module.exports = router;
