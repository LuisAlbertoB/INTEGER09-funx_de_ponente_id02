const express = require('express');
const router = express.Router();
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const eventosService = require('../services/eventos.service');
const verifyToken = require('../middlewares/verifyToken');

router.use(verifyToken);

// ── Multer para imágenes de eventos ───────────────────────
const _storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = path.resolve(process.cwd(), 'uploads/eventos');
    fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
    cb(null, `evento_${req.params.id}_${Date.now()}${ext}`);
  },
});
const _upload = multer({
  storage: _storage,
  limits: { fileSize: 8 * 1024 * 1024 }, // 8 MB
  fileFilter: (req, file, cb) => {
    const imageExts = /\.(jpg|jpeg|png|gif|webp|heic|heif)$/i;
    const isImageMime = file.mimetype.startsWith('image/');
    const isImageExt = imageExts.test(file.originalname);
    if (isImageMime || isImageExt) cb(null, true);
    else cb(new Error('Solo se permiten imágenes (jpg, png, webp, heic).'));
  },
});

// GET /api/eventos -> Listar eventos
router.get('/', async (req, res) => {
  try {
    const result = await eventosService.listEventos(req.query);
    return res.status(200).json(result);
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// GET /api/eventos/mis-inscripciones  ← BEFORE /:id to avoid route collision
router.get('/mis-inscripciones', async (req, res) => {
  try {
    const inscripciones = await eventosService.getMisInscripciones(req.user.id_usuario);
    return res.status(200).json(inscripciones);
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// POST /api/eventos -> Crear evento
router.post('/', async (req, res) => {
  try {
    const evento = await eventosService.createEvento(req.user.id_usuario, req.body);
    return res.status(201).json({ message: 'Evento creado.', evento });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// GET /api/eventos/:id -> Detalle de evento
router.get('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const evento = await eventosService.getEventoById(id);
    return res.status(200).json(evento);
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// PUT /api/eventos/:id -> Editar evento
router.put('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const evento = await eventosService.updateEvento(id, req.body);
    return res.status(200).json({ message: 'Evento actualizado.', evento });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// DELETE /api/eventos/:id -> Eliminar evento
router.delete('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    await eventosService.deleteEvento(id);
    return res.status(200).json({ message: 'Evento eliminado.' });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// GET /api/eventos/:id/inscripciones -> Participantes del evento
router.get('/:id/inscripciones', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const participantes = await eventosService.getParticipantes(id);
    return res.status(200).json(participantes);
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// POST /api/eventos/:id/inscribir -> Inscribirse
router.post('/:id/inscribir', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const inscripcion = await eventosService.inscribirseEvento(req.user.id_usuario, id);
    return res.status(201).json({ message: 'Inscripción exitosa.', inscripcion });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// DELETE /api/eventos/:id/inscribir -> Cancelar inscripción
router.delete('/:id/inscribir', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    await eventosService.desinscribirseEvento(req.user.id_usuario, id);
    return res.status(200).json({ message: 'Inscripción cancelada.' });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// POST /api/eventos/:id/imagen — sube y guarda imagen del evento
router.post('/:id/imagen', (req, res, next) => {
  _upload.single('imagen')(req, res, (err) => {
    if (err) {
      return res.status(400).json({ message: err.message || 'Error al procesar la imagen.' });
    }
    next();
  });
}, async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  if (!req.file) return res.status(400).json({ message: 'No se recibió ninguna imagen.' });
  try {
    const url_imagen = `/uploads/eventos/${req.file.filename}`;
    await eventosService.updateEvento(id, { url_imagen });
    return res.status(200).json({ message: 'Imagen actualizada.', url_imagen });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// POST /api/eventos/:id/solicitar-espacio/:id_espacio
router.post('/:id/solicitar-espacio/:id_espacio', async (req, res) => {
  const idEvento = Number(req.params.id);
  const idEspacio = Number(req.params.id_espacio);
  if (isNaN(idEvento) || isNaN(idEspacio)) {
    return res.status(400).json({ message: 'IDs inválidos.' });
  }
  try {
    const solicitud = await eventosService.solicitarEspacio(req.user.id_usuario, idEvento, idEspacio, req.body);
    return res.status(201).json({ message: 'Solicitud enviada.', solicitud });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// GET /api/eventos/:id/foro
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

// POST /api/eventos/:id/foro
router.post('/:id/foro', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const comentario = await eventosService.postComentarioForo(req.user.id_usuario, id, req.body);
    return res.status(201).json({ message: 'Comentario publicado.', comentario });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// POST /api/eventos/:id/evaluacion
router.post('/:id/evaluacion', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const evaluacion = await eventosService.submitEvaluacion(req.user.id_usuario, id, req.body);
    return res.status(201).json({ message: 'Evaluación recibida.', evaluacion });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

// POST /api/eventos/:id/feedback-asistente
router.post('/:id/feedback-asistente', async (req, res) => {
  const id = Number(req.params.id);
  if (isNaN(id)) return res.status(400).json({ message: 'ID inválido.' });
  try {
    const feedback = await eventosService.submitFeedbackAsistente(req.user.id_usuario, id, req.body);
    return res.status(201).json({ message: 'Feedback guardado.', feedback });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message });
  }
});

module.exports = router;
