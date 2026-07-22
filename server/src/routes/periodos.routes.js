const express = require('express');
const router = express.Router();
const verifyToken = require('../middlewares/verifyToken');
const verifyAdmin = require('../middlewares/verifyAdmin');
const periodosService = require('../services/periodos.service');

// GET /api/periodos
router.get('/', async (req, res) => {
  try {
    const periodos = await periodosService.getPeriodos();
    return res.status(200).json(periodos);
  } catch (error) {
    console.error('Error en getPeriodos:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// GET /api/periodos/active
router.get('/active', async (req, res) => {
  try {
    const periodo = await periodosService.getActivePeriodDetails();
    return res.status(200).json(periodo);
  } catch (error) {
    console.error('Error en getActivePeriod:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// POST /api/periodos – Solo admin
router.post('/', verifyToken, verifyAdmin, async (req, res) => {
  try {
    const nuevoPeriodo = await periodosService.createPeriodo(req.body);
    return res.status(201).json({ message: 'Periodo creado.', periodo: nuevoPeriodo });
  } catch (error) {
    console.error('Error en createPeriodo:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error al crear el periodo escolar.' });
  }
});

// PUT /api/periodos/:id – Solo admin
router.put('/:id', verifyToken, verifyAdmin, async (req, res) => {
  const id = Number(req.params.id);
  try {
    const periodoActualizado = await periodosService.updatePeriodo(id, req.body);
    return res.status(200).json({ message: 'Periodo actualizado.', periodo: periodoActualizado });
  } catch (error) {
    console.error('Error en updatePeriodo:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

module.exports = router;
