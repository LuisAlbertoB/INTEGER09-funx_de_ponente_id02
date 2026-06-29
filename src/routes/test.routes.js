const express = require('express');
const router = express.Router();
const marketplaceScenario = require('../controllers/scenarios/marketplace.scenario');
const StateStore = require('../store/StateStore');

// GET /api/test/run-all
router.get('/run-all', async (req, res) => {
  try {
    StateStore.clear(); // Limpia estado de pruebas anteriores
    const result = await marketplaceScenario.runMarketplaceScenario();
    
    if (result.success) {
      return res.status(200).json({ message: 'Todos los escenarios pasaron exitosamente.', result });
    } else {
      return res.status(500).json({ message: 'La prueba falló.', result });
    }
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

// GET /api/test/status
router.get('/status', (req, res) => {
  res.status(200).json({
    state: StateStore.state // Devuelve el JSON del estado actual de la Test Machine
  });
});

module.exports = router;
