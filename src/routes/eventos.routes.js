const express = require('express');
const router = express.Router();
const eventosService = require('../services/eventos.service');
const verifyToken = require('../middlewares/verifyToken');

router.use(verifyToken);

// POST /api/eventos -> Crear evento/borrador
router.post('/', async (req, res) => {
  try {
    const evento = await eventosService.createEvento(req.userId, req.body);
    return res.status(201).json({ message: 'Evento creado.', evento });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// POST /api/eventos/:id/solicitar-espacio/:id_espacio -> Pedir sala
router.post('/:id/solicitar-espacio/:id_espacio', async (req, res) => {
  const idEvento = Number(req.params.id);
  const idEspacio = Number(req.params.id_espacio);
  
  if (isNaN(idEvento) || isNaN(idEspacio)) {
    return res.status(400).json({ message: 'IDs inválidos.' });
  }

  try {
    const solicitud = await eventosService.solicitarEspacio(req.userId, idEvento, idEspacio, req.body);
    return res.status(201).json({ message: 'Solicitud enviada al dueño del espacio.', solicitud });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// GET /api/eventos/:id/foro -> Leer comunidad
router.get('/:id/foro', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  
  try {
    const comentarios = await eventosService.getForo(id);
    return res.status(200).json(comentarios);
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// POST /api/eventos/:id/foro -> Publicar en comunidad
router.post('/:id/foro', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  
  try {
    const comentario = await eventosService.postComentarioForo(req.userId, id, req.body);
    return res.status(201).json({ message: 'Comentario publicado.', comentario });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// POST /api/eventos/:id/evaluacion -> Enviar reseña (Data NLP)
router.post('/:id/evaluacion', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  
  try {
    const evaluacion = await eventosService.submitEvaluacion(req.userId, id, req.body);
    return res.status(201).json({ message: 'Evaluación recibida con éxito.', evaluacion });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

module.exports = router;
