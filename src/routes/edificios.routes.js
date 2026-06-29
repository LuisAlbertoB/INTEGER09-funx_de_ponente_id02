const express = require('express');
const router = express.Router();
const edificiosService = require('../services/edificios.service');
const verifyToken = require('../middlewares/verifyToken');
const verifyAdmin = require('../middlewares/verifyAdmin');

router.use(verifyToken);

// GET /api/edificios
router.get('/', async (req, res) => {
  try {
    const edificios = await edificiosService.getEdificios();
    return res.status(200).json(edificios);
  } catch (error) {
    console.error('Error en getEdificios:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// GET /api/edificios/:id
router.get('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const edificio = await edificiosService.getEdificioById(id);
    return res.status(200).json(edificio);
  } catch (error) {
    console.error('Error en getEdificioById:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// POST /api/edificios - Solo admin
router.post('/', verifyAdmin, async (req, res) => {
  try {
    const nuevoEdificio = await edificiosService.createEdificio(req.body);
    return res.status(201).json({ message: 'Edificio creado.', edificio: nuevoEdificio });
  } catch (error) {
    console.error('Error en createEdificio:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// PUT /api/edificios/:id - Solo admin
router.put('/:id', verifyAdmin, async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const edificio = await edificiosService.updateEdificio(id, req.body);
    return res.status(200).json({ message: 'Edificio actualizado.', edificio });
  } catch (error) {
    console.error('Error en updateEdificio:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// DELETE /api/edificios/:id - Solo admin
router.delete('/:id', verifyAdmin, async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    await edificiosService.deleteEdificio(id);
    return res.status(200).json({ message: 'Edificio desactivado correctamente.' });
  } catch (error) {
    console.error('Error en deleteEdificio:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

module.exports = router;
