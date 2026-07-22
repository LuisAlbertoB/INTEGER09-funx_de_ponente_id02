const catalogoClient = require('../../services/apiClients/catalogo.client');
const socialClient   = require('../../services/apiClients/social.client');
const reportesClient = require('../../services/apiClients/reportes.client');
const espaciosClient = require('../../services/apiClients/espacios.client');
const ponente        = require('../../services/apiClients/ponente.client');
const adminClient    = require('../../services/apiClients/admin.client');
const baseClient     = require('../../services/apiClients/base.client');
const StateStore     = require('../../store/StateStore');

const runSocialScenario = async () => {
  const log = [];
  const pushLog = (msg) => { console.log(msg); log.push({ time: new Date(), message: msg }); };

  try {
    const idEvento  = StateStore.get('last_evento_id');
    let   periodoId = StateStore.get('active_periodo_id');
    let   aulaId    = StateStore.get('test_aula_id') || 1;

    // Resolver periodo si no está en estado (escenario individual)
    if (!periodoId) {
      const p = await adminClient.getPeriodoActivo();
      periodoId = p.id_periodo;
      StateStore.set('active_periodo_id', periodoId);
    }

    // ── Catálogo ──────────────────────────────────────────────────────────
    pushLog('[S01] GET /api/catalogo/espacios?page=1&limit=5...');
    const espaciosCat = await catalogoClient.getEspacios(1, 5);
    pushLog(`✅ Catálogo de espacios: ${espaciosCat.meta.totalRegistros} registros, ${espaciosCat.meta.paginasTotales} páginas.`);

    pushLog('[S02] GET /api/catalogo/eventos?page=1&limit=5...');
    const eventosCat = await catalogoClient.getEventos(1, 5);
    pushLog(`✅ Catálogo de eventos: ${eventosCat.meta.totalRegistros} registros.`);

    // ── Foro Social ───────────────────────────────────────────────────────
    if (!idEvento) throw new Error('No hay evento en estado. Ejecuta run-all o marketplace primero.');

    pushLog(`[S03] GET /api/eventos/${idEvento}/foro - Leer foro...`);
    await socialClient.getForo(idEvento);
    pushLog('✅ Foro del evento leído.');

    pushLog(`[S04] POST /api/eventos/${idEvento}/foro - Comentar en foro...`);
    const comentario = await socialClient.postComentario(idEvento, {
      mensaje: 'Excelente evento. [Test Machine E2E]'
    });
    const comentarioId = comentario.comentario.id_comentario;
    pushLog(`✅ Comentario publicado con ID: ${comentarioId}`);

    pushLog(`[S05] POST /api/eventos/${idEvento}/foro - Responder en hilo...`);
    await socialClient.postComentario(idEvento, {
      mensaje: '¡De acuerdo! [Test Machine E2E Reply]',
      id_comentario_padre: comentarioId
    });
    pushLog('✅ Respuesta en hilo publicada.');

    // ── Módulo Ponente ────────────────────────────────────────────────────
    pushLog('[S06] GET /api/ponente/conferencias - Listar conferencias...');
    await ponente.getMisConferencias();
    pushLog('✅ Conferencias del ponente listadas.');

    pushLog('[S07] POST /api/ponente/conferencias - Crear conferencia...');
    const conf = await ponente.createConferencia({
      titulo: `Conf Ponente E2E ${Date.now()}`,
      descripcion: 'Conferencia de prueba vía módulo de ponente',
      id_actividad: StateStore.get('primera_actividad_id') || 3,
      id_periodo: periodoId
    });
    const confId = conf.conferencia.id_conferencia;
    StateStore.set('test_conferencia_ponente_id', confId);
    pushLog(`✅ Conferencia creada con ID: ${confId}`);

    pushLog(`[S08] PUT /api/ponente/conferencias/${confId} - Actualizar conferencia...`);
    await ponente.updateConferencia(confId, { titulo: `Conf E2E Updated ${Date.now()}` });
    pushLog('✅ Conferencia actualizada.');

    // ── Mis Espacios ──────────────────────────────────────────────────────
    pushLog('[S09] GET /api/mis-espacios - Listar mis espacios...');
    const misEspaciosRes = await baseClient.get('/api/mis-espacios');
    pushLog(`✅ Mis Espacios listados: ${misEspaciosRes.data.length ?? '?'} registros.`);

    pushLog('[S10] GET /api/mis-espacios/solicitudes - Ver solicitudes recibidas...');
    await espaciosClient.getSolicitudes();
    pushLog('✅ Solicitudes recibidas listadas.');

    // ── Reportes ──────────────────────────────────────────────────────────
    pushLog('[S11] GET /api/reportes...');
    await reportesClient.getReportes();
    pushLog('✅ Lista de reportes obtenida.');

    pushLog('[S12] POST /api/reportes - Crear reporte...');
    const reporte = await reportesClient.createReporte({
      titulo: `Reporte E2E ${Date.now()}`,       // campo requerido
      descripcion: 'Reporte generado por Test Machine',
      id_aula: aulaId                              // campo requerido
    });
    const reporteId = reporte.reporte?.id_reporte;
    if (reporteId) {
      StateStore.set('test_reporte_id', reporteId);
      pushLog(`✅ Reporte creado con ID: ${reporteId}`);

      pushLog(`[S13] PUT /api/reportes/${reporteId} - Actualizar reporte...`);
      await reportesClient.updateReporte(reporteId, { descripcion: 'Actualizado por Test Machine' });
      pushLog('✅ Reporte actualizado.');
    } else {
      pushLog('⚠️  Reporte creado (sin ID retornado, verificar schema de reportes).');
    }

    return { success: true, log };

  } catch (error) {
    const errorMsg = error.response
      ? `HTTP ${error.response.status}: ${JSON.stringify(error.response.data)}`
      : error.message;
    pushLog(`❌ FALLO: ${errorMsg}`);
    return { success: false, log, error: errorMsg };
  }
};

module.exports = { runSocialScenario };
