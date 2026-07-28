const express = require('express');
const router = express.Router();
const verifyToken = require('../middlewares/verifyToken');
const nlp = require('../services/incidents_nlp.service');

router.use(verifyToken);

/**
 * POST /api/nlp/analizar
 * Clasifica el texto de una incidencia.
 * Body: { texto: string }
 */
router.post('/analizar', (req, res) => {
  const { texto } = req.body;
  if (!texto || typeof texto !== 'string') {
    return res.status(400).json({ message: 'El campo "texto" es requerido.' });
  }
  try {
    const resultado = nlp.analizar(texto.trim());
    return res.status(200).json(resultado);
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
});

/**
 * POST /api/nlp/similares
 * Busca incidencias similares al texto enviado.
 * Body: {
 *   texto: string,
 *   incidencias: [{ id: string, descripcion: string }]
 * }
 */
router.post('/similares', (req, res) => {
  const { texto, incidencias } = req.body;
  if (!texto || typeof texto !== 'string') {
    return res.status(400).json({ message: 'El campo "texto" es requerido.' });
  }
  if (!Array.isArray(incidencias)) {
    return res.status(400).json({ message: 'El campo "incidencias" debe ser un arreglo.' });
  }
  try {
    const similares = nlp.buscarSimilares(texto.trim(), incidencias);
    return res.status(200).json({ similares });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
});

module.exports = router;
