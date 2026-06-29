const express = require('express');
const router = express.Router();
const StateStore = require('../store/StateStore');
const { runAdminScenario }       = require('../controllers/scenarios/admin.scenario');
const { runMarketplaceScenario } = require('../controllers/scenarios/marketplace.scenario');
const { runSocialScenario }      = require('../controllers/scenarios/social.scenario');

// ── GET /api/test/run-all ──────────────────────────────────────────────────
// Ejecuta todos los escenarios en secuencia y devuelve el reporte completo
router.get('/run-all', async (req, res) => {
  StateStore.clear();
  const startTime = Date.now();
  const reporte = {};

  console.log('\n══════════════════════════════════════════════');
  console.log('  🤖 TEST MACHINE — INICIO DE PRUEBA COMPLETA');
  console.log('══════════════════════════════════════════════\n');

  // 1. Admin Scenario (Prepara catálogos base)
  console.log('▶️  Escenario 1: Admin Panel\n');
  reporte.admin = await runAdminScenario();

  // 2. Marketplace Scenario (Flujo de espacios y eventos)
  console.log('\n▶️  Escenario 2: Marketplace (Espacios + Eventos)\n');
  reporte.marketplace = await runMarketplaceScenario();

  // 3. Social Scenario (Foro, Catálogo, Reportes, Ponente)
  console.log('\n▶️  Escenario 3: Social (Foro + Catálogo + Reportes)\n');
  reporte.social = await runSocialScenario();

  const totalMs = Date.now() - startTime;
  const allPassed = Object.values(reporte).every(r => r.success);
  const totalPasos = Object.values(reporte).reduce((acc, r) => acc + r.log.length, 0);

  console.log(`\n══════════════════════════════════════════════`);
  console.log(`  ${allPassed ? '✅ TODAS LAS PRUEBAS PASARON' : '❌ ALGUNAS PRUEBAS FALLARON'}`);
  console.log(`  ${totalPasos} pasos ejecutados en ${totalMs}ms`);
  console.log(`══════════════════════════════════════════════\n`);

  return res.status(allPassed ? 200 : 500).json({
    success: allPassed,
    total_pasos: totalPasos,
    duracion_ms: totalMs,
    escenarios: {
      admin:        { success: reporte.admin.success,       pasos: reporte.admin.log.length },
      marketplace:  { success: reporte.marketplace.success, pasos: reporte.marketplace.log.length },
      social:       { success: reporte.social.success,      pasos: reporte.social.log.length },
    },
    reporte_completo: reporte
  });
});

// ── GET /api/test/run/:scenario ────────────────────────────────────────────
// Corre un escenario individual
router.get('/run/:scenario', async (req, res) => {
  const scenarios = {
    admin:       runAdminScenario,
    marketplace: runMarketplaceScenario,
    social:      runSocialScenario,
  };
  const fn = scenarios[req.params.scenario];
  if (!fn) {
    return res.status(404).json({ message: `Escenario "${req.params.scenario}" no existe. Disponibles: ${Object.keys(scenarios).join(', ')}` });
  }
  StateStore.clear();
  const result = await fn();
  return res.status(result.success ? 200 : 500).json(result);
});

// ── GET /api/test/status ───────────────────────────────────────────────────
router.get('/status', (req, res) => {
  res.status(200).json({ state: StateStore.state });
});

module.exports = router;
