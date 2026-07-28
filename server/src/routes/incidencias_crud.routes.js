const express = require('express');
const router = express.Router();
const verifyToken = require('../middlewares/verifyToken');
const svc = require('../services/incidencias.service');

router.use(verifyToken);

// GET /api/incidencias?conferencia_id=X&estado=open
router.get('/', async (req, res) => {
  try {
    const items = await svc.listar(req.query);
    return res.json(items);
  } catch (e) {
    return res.status(500).json({ message: e.message });
  }
});

// POST /api/incidencias
router.post('/', async (req, res) => {
  const { descripcion, categoria, prioridad, ubicacion, nombre_evento, reportado_por } = req.body;
  if (!descripcion || typeof descripcion !== 'string') {
    return res.status(400).json({ message: 'El campo "descripcion" es requerido.' });
  }
  try {
    // Inyecta el id del usuario autenticado si está disponible
    const data = { ...req.body, id_usuario: req.user?.id ?? req.user?.id_usuario ?? null };
    const inc = await svc.crear(data);
    return res.status(201).json(inc);
  } catch (e) {
    return res.status(500).json({ message: e.message });
  }
});

// PUT /api/incidencias/:dbId/estado
router.put('/:dbId/estado', async (req, res) => {
  const { estado } = req.body;
  const estadosValidos = ['open', 'inProgress', 'resolved', 'closed'];
  if (!estadosValidos.includes(estado)) {
    return res.status(400).json({ message: `Estado inválido. Usa: ${estadosValidos.join(', ')}` });
  }
  try {
    const inc = await svc.actualizarEstado(req.params.dbId, estado);
    return res.json(inc);
  } catch (e) {
    return res.status(500).json({ message: e.message });
  }
});

// POST /api/incidencias/:dbId/unirse
router.post('/:dbId/unirse', async (req, res) => {
  try {
    const inc = await svc.unirse(req.params.dbId);
    return res.json(inc);
  } catch (e) {
    return res.status(500).json({ message: e.message });
  }
});

module.exports = router;
