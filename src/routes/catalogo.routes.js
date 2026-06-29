const express = require('express');
const router = express.Router();
const catalogoService = require('../services/catalogo.service');
const verifyToken = require('../middlewares/verifyToken');

// Opcional: Proteger el catálogo, o dejarlo público
router.use(verifyToken);

// GET /api/catalogo/espacios?page=1&limit=10&buscar=Lab
router.get('/espacios', async (req, res) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.max(1, Number(req.query.limit) || 10);
    const { buscar } = req.query;

    const result = await catalogoService.getEspacios(page, limit, { buscar });
    return res.status(200).json(result);
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// GET /api/catalogo/eventos?page=1&limit=10&tematica=IA
router.get('/eventos', async (req, res) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.max(1, Number(req.query.limit) || 10);
    const { tematica } = req.query;

    const result = await catalogoService.getEventos(page, limit, { tematica });
    return res.status(200).json(result);
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

module.exports = router;
