const express = require('express');
const router = express.Router();
const verifyToken = require('../middlewares/verifyToken');
const verifyPonente = require('../middlewares/verifyPonente');
const verifyOwner = require('../middlewares/verifyOwner');
const upload = require('../middlewares/upload');
const {
  getMisConferencias,
  createConferencia,
  updateConferencia,
  deleteConferencia,
  uploadMaterial,
  injectConferenciaOwner
} = require('../controllers/ponente.controller');

// Todas las rutas del ponente requieren autenticación y rol ponente/admin
router.use(verifyToken);
router.use(verifyPonente);

// Rutas base de conferencias
router.get('/conferencias', getMisConferencias);
router.post('/conferencias', createConferencia);

// Rutas de conferencia específica que requieren ser el dueño
router.put('/conferencias/:id', injectConferenciaOwner, verifyOwner, updateConferencia);
router.delete('/conferencias/:id', injectConferenciaOwner, verifyOwner, deleteConferencia);

// Rutas de materiales
// El middleware `upload.single('archivo')` intercepta el formData donde el archivo se llama 'archivo'
router.post('/conferencias/:id/materiales', upload.single('archivo'), injectConferenciaOwner, verifyOwner, uploadMaterial);

module.exports = router;
