const authClient = require('../../services/apiClients/auth.client');
const espaciosClient = require('../../services/apiClients/espacios.client');
const eventosClient = require('../../services/apiClients/eventos.client');
const StateStore = require('../../store/StateStore');

// ─── Credenciales reales de la DB ──────────────────────────────────────────
const ADMIN_MATRICULA   = '000000';
const ADMIN_PASS        = 'admin1';
// Actualiza estas constantes cuando agregues usuarios de cada rol
const PONENTE_MATRICULA = '000000'; // TODO: cambiar a matricula del ponente cuando tenga contraseña confirmada
const PONENTE_PASS      = 'admin1';

const runMarketplaceScenario = async () => {
  const log = [];
  const pushLog = (msg) => {
    console.log(msg);
    log.push({ time: new Date(), message: msg });
  };

  try {
    // ── PASO 01: Health check de autenticación ───────────────────────────────
    pushLog('[01] Login Admin...');
    await authClient.login(ADMIN_MATRICULA, ADMIN_PASS, 'admin_token');
    StateStore.set('active_token', StateStore.get('admin_token'));
    pushLog('✅ Admin autenticado.');

    // ── PASO 02: Admin actúa como Ponente y publica su Espacio ───────────────
    pushLog('[02] Admin (rol Ponente) publica un Espacio en Edificio A...');
    const espacio = await espaciosClient.createEspacio({
      nombre_clave: `Lab E2E ${Date.now()}`,
      id_edificio: 1
    });
    StateStore.set('last_espacio_id', espacio.espacio.id_aula);
    pushLog(`✅ Espacio creado con ID: ${espacio.espacio.id_aula}`);

    // ── PASO 03: Admin crea el Evento (como Event Manager) ───────────────────
    pushLog('[03] Admin (rol Coordinador) crea un Evento tipo Conferencia...');
    const evento = await eventosClient.createEvento({
      titulo: `Conferencia E2E ${Date.now()}`,
      descripcion: 'Evento generado automáticamente por la Test Machine.',
      id_actividad: 4  // Actividad "Conferencia" del seed
    });
    StateStore.set('last_evento_id', evento.evento.id_conferencia);
    pushLog(`✅ Evento creado con ID: ${evento.evento.id_conferencia}`);

    // ── PASO 04: Admin solicita su propio espacio para el evento ────────────
    pushLog('[04] Admin solicita el Espacio para el Evento...');
    const solicitud = await eventosClient.solicitarEspacio(
      StateStore.get('last_evento_id'),
      StateStore.get('last_espacio_id'),
      {
        fecha_inicio: new Date().toISOString(),
        fecha_final: new Date(Date.now() + 3600000).toISOString(),
        motivo: 'Test Machine E2E Automation'
      }
    );
    StateStore.set('last_solicitud_id', solicitud.solicitud.id_solicitud);
    pushLog(`✅ Solicitud enviada con ID: ${solicitud.solicitud.id_solicitud}`);

    // ── PASO 05: Admin (como Ponente-Dueño) aprueba la solicitud ────────────
    pushLog('[05] Admin (rol Ponente) aprueba la solicitud de espacio...');
    await espaciosClient.aprobarSolicitud(StateStore.get('last_solicitud_id'));
    pushLog('✅ Solicitud aprobada correctamente.');

    // ── PASO 06: Admin evalúa el evento ─────────────────────────────────────
    pushLog('[06] Admin envía evaluación del evento (datos NLP)...');
    await eventosClient.submitEvaluacion(StateStore.get('last_evento_id'), {
      calificacion: 5.0,
      porcentaje_satisfaccion: 100,
      comentario_escrito: 'Flujo E2E verificado exitosamente por la Test Machine.'
    });
    pushLog('✅ Evaluación enviada. ¡Flujo completo verificado!');

    return {
      success: true,
      total_pasos: 6,
      ids_generados: {
        espacio_id: StateStore.get('last_espacio_id'),
        evento_id: StateStore.get('last_evento_id'),
        solicitud_id: StateStore.get('last_solicitud_id')
      },
      log
    };

  } catch (error) {
    const errorMsg = error.response
      ? `HTTP ${error.response.status}: ${JSON.stringify(error.response.data)}`
      : error.message;
    pushLog(`❌ FALLO: ${errorMsg}`);
    return { success: false, log, error: errorMsg };
  }
};

module.exports = { runMarketplaceScenario };
