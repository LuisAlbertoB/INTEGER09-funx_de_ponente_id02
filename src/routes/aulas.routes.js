const express = require('express');
const router = express.Router();
const aulasService = require('../services/aulas.service');
const verifyToken = require('../middlewares/verifyToken');
const verifyAdmin = require('../middlewares/verifyAdmin');

router.use(verifyToken);

// GET /api/aulas
router.get('/', async (req, res) => {
  try {
    const aulas = await aulasService.getAulas();
    return res.status(200).json(aulas);
  } catch (error) {
    console.error('Error en getAulas:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// GET /api/aulas/:id
router.get('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const aula = await aulasService.getAulaById(id);
    return res.status(200).json(aula);
  } catch (error) {
    console.error('Error en getAulaById:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// POST /api/aulas - Solo admin
router.post('/', verifyAdmin, async (req, res) => {
  try {
    const nuevaAula = await aulasService.createAula(req.body);
    return res.status(201).json({ message: 'Aula creada.', aula: nuevaAula });
  } catch (error) {
    console.error('Error en createAula:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// PUT /api/aulas/:id - Solo admin
router.put('/:id', verifyAdmin, async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const aula = await aulasService.updateAula(id, req.body);
    return res.status(200).json({ message: 'Aula actualizada.', aula });
  } catch (error) {
    console.error('Error en updateAula:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// DELETE /api/aulas/:id - Solo admin
router.delete('/:id', verifyAdmin, async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    await aulasService.deleteAula(id);
    return res.status(200).json({ message: 'Aula desactivada correctamente.' });
  } catch (error) {
    console.error('Error en deleteAula:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

module.exports = router;
