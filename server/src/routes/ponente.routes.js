const express = require('express');
const router = express.Router();
const verifyToken = require('../middlewares/verifyToken');
const verifyPonente = require('../middlewares/verifyPonente');
const verifyOwner = require('../middlewares/verifyOwner');
const upload = require('../middlewares/upload');
const ponenteService = require('../services/ponente.service');

// Todas las rutas del ponente requieren autenticación y rol ponente/admin
router.use(verifyToken);
router.use(verifyPonente);

// Middleware para inyectar resourceOwnerId antes de verifyOwner
const injectConferenciaOwner = async (req, res, next) => {
  try {
    req.resourceOwnerId = await ponenteService.getConferenciaOwner(Number(req.params.id));
    next();
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno.' });
  }
};

// GET /api/ponente/conferencias
router.get('/conferencias', async (req, res) => {
  try {
    const conferencias = await ponenteService.getMisConferencias(req.user.id_usuario);
    return res.status(200).json(conferencias);
  } catch (error) {
    console.error('Error en getMisConferencias:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// POST /api/ponente/conferencias
router.post('/conferencias', async (req, res) => {
  try {
    const nuevaConferencia = await ponenteService.createConferencia(req.body, req.user.id_usuario);
    return res.status(201).json({ message: 'Conferencia creada.', conferencia: nuevaConferencia });
  } catch (error) {
    console.error('Error en createConferencia:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error al crear la conferencia.' });
  }
});

// PUT /api/ponente/conferencias/:id
router.put('/conferencias/:id', injectConferenciaOwner, verifyOwner, async (req, res) => {
  try {
    const actualizada = await ponenteService.updateConferencia(
      Number(req.params.id), req.body, req.user.id_usuario, req.user.rol, req.isOwner
    );
    return res.status(200).json({ message: 'Conferencia actualizada.', conferencia: actualizada });
  } catch (error) {
    console.error('Error en updateConferencia:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error al actualizar la conferencia.' });
  }
});

// DELETE /api/ponente/conferencias/:id
router.delete('/conferencias/:id', injectConferenciaOwner, verifyOwner, async (req, res) => {
  try {
    await ponenteService.deleteConferencia(Number(req.params.id), req.isOwner, req.user.rol);
    return res.status(200).json({ message: 'Conferencia eliminada correctamente.' });
  } catch (error) {
    console.error('Error en deleteConferencia:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

// POST /api/ponente/conferencias/:id/materiales
router.post('/conferencias/:id/materiales', upload.single('archivo'), injectConferenciaOwner, verifyOwner, async (req, res) => {
  try {
    const material = await ponenteService.uploadMaterial(
      Number(req.params.id), req.body, req.file, req.isOwner, req.user.rol
    );
    return res.status(201).json({ message: 'Material subido exitosamente.', material });
  } catch (error) {
    console.error('Error en uploadMaterial:', error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'Error interno del servidor.' });
  }
});

module.exports = router;
