const adminClient = require('../../services/apiClients/admin.client');
const authClient  = require('../../services/apiClients/auth.client');
const StateStore  = require('../../store/StateStore');

const runAdminScenario = async () => {
  const log = [];
  const pushLog = (msg) => { console.log(msg); log.push({ time: new Date(), message: msg }); };

  try {
    // ── Login ─────────────────────────────────────────────────────────────
    pushLog('[A00] Login Admin (inicializando token)...');
    await authClient.login('000000', 'admin1', 'admin_token');
    StateStore.set('active_token', StateStore.get('admin_token'));
    pushLog('✅ Admin autenticado.');

    // ── Usuarios ──────────────────────────────────────────────────────────
    pushLog('[A01] GET /api/usuarios...');
    await adminClient.getUsuarios();
    pushLog('✅ Lista de usuarios obtenida.');

    pushLog('[A02] POST /api/usuarios - Crear usuario de prueba...');
    const ts = Date.now();
    const nuevoUser = await adminClient.createUsuario({
      nombre_completo: `Test User ${ts}`,
      matricula: `T${ts}`.slice(-7),
      contrasena: 'test1234',
      rol: 'ponente'
    });
    const newUserId = nuevoUser.usuario.id_usuario;
    StateStore.set('test_user_id', newUserId);
    pushLog(`✅ Usuario creado con ID: ${newUserId}`);

    pushLog('[A03] PUT /api/usuarios/:id/estado - Desactivar usuario...');
    await adminClient.updateEstadoUsuario(newUserId, 0);
    pushLog('✅ Estado de usuario actualizado.');

    // ── Edificios ─────────────────────────────────────────────────────────
    pushLog('[A04] GET /api/edificios...');
    const edificios = await adminClient.getEdificios();
    const primerEdifId = edificios[0].id_edificio;

    pushLog(`[A05] GET /api/edificios/${primerEdifId}...`);
    await adminClient.getEdificioById(primerEdifId);
    pushLog('✅ Edificio por ID obtenido.');

    pushLog('[A06] POST /api/edificios - Crear edificio...');
    const edif = await adminClient.createEdificio({ nombre_clave: `Edif-E2E-${ts}`, estado: 1 });
    const newEdifId = edif.edificio.id_edificio;
    StateStore.set('test_edificio_id', newEdifId);
    pushLog(`✅ Edificio creado con ID: ${newEdifId}`);

    pushLog('[A07] PUT /api/edificios/:id - Actualizar edificio...');
    await adminClient.updateEdificio(newEdifId, { nombre_clave: `Edif-E2E-Upd-${ts}` });
    pushLog('✅ Edificio actualizado.');

    // ── Aulas ─────────────────────────────────────────────────────────────
    pushLog('[A08] GET /api/aulas...');
    const aulas = await adminClient.getAulas();
    const primerAulaId = aulas[0].id_aula;

    pushLog(`[A09] GET /api/aulas/${primerAulaId}...`);
    await adminClient.getAulaById(primerAulaId);
    pushLog('✅ Aula por ID obtenida.');

    pushLog('[A10] POST /api/aulas - Crear aula...');
    const aula = await adminClient.createAula({ nombre_clave: `Aula-E2E-${ts}`, id_edificio: primerEdifId });
    const newAulaId = aula.aula.id_aula;
    StateStore.set('test_aula_id', newAulaId);
    pushLog(`✅ Aula creada con ID: ${newAulaId}`);

    pushLog('[A11] PUT /api/aulas/:id - Actualizar aula...');
    await adminClient.updateAula(newAulaId, { nombre_clave: `Aula-E2E-Upd-${ts}` });
    pushLog('✅ Aula actualizada.');

    // ── Actividades ───────────────────────────────────────────────────────
    pushLog('[A12] GET /api/actividades...');
    const actividades = await adminClient.getActividades();
    const primerActId = actividades[0].id_actividad; // ID dinámico, no hardcoded
    StateStore.set('primera_actividad_id', primerActId);

    pushLog(`[A13] GET /api/actividades/${primerActId}...`);
    await adminClient.getActividadById(primerActId);
    pushLog('✅ Actividad por ID obtenida.');

    pushLog('[A14] POST /api/actividades - Crear actividad...');
    const act = await adminClient.createActividad({
      titulo_actividad: `Act-E2E-${ts}`,
      subtitulo_actividad: 'E2E Test',
      descripcion: 'Actividad generada por Test Machine'
    });
    const newActId = act.actividad.id_actividad;
    StateStore.set('test_actividad_id', newActId);
    pushLog(`✅ Actividad creada con ID: ${newActId}`);

    pushLog('[A15] PUT /api/actividades/:id - Actualizar actividad...');
    await adminClient.updateActividad(newActId, { titulo_actividad: `Act-E2E-Upd-${ts}` });
    pushLog('✅ Actividad actualizada.');

    // ── Mobiliario ────────────────────────────────────────────────────────
    pushLog('[A16] GET /api/mobiliario...');
    const mobiliario = await adminClient.getMobiliario();
    const primerMobId = mobiliario[0].id_inmobiliario;

    pushLog(`[A17] GET /api/mobiliario/${primerMobId}...`);
    await adminClient.getMobiliarioById(primerMobId);
    pushLog('✅ Mobiliario por ID obtenido.');

    pushLog('[A18] POST /api/mobiliario - Crear mobiliario...');
    const mob = await adminClient.createMobiliario({
      categoria: 'Tecnología',
      nombre: `Laptop E2E ${ts}`,
      modelo: 'Test Model',
      stock_disponible: 5
    });
    const newMobId = mob.mobiliario.id_inmobiliario;
    StateStore.set('test_mob_id', newMobId);
    pushLog(`✅ Mobiliario creado con ID: ${newMobId}`);

    pushLog('[A19] PUT /api/mobiliario/:id - Actualizar mobiliario...');
    await adminClient.updateMobiliario(newMobId, { stock_disponible: 3 });
    pushLog('✅ Mobiliario actualizado.');

    // ── Periodos ──────────────────────────────────────────────────────────
    pushLog('[A20] GET /api/periodos...');
    await adminClient.getPeriodos();
    pushLog('✅ Lista de periodos obtenida.');

    pushLog('[A21] GET /api/periodos/active...');
    const periodoActivo = await adminClient.getPeriodoActivo();
    StateStore.set('active_periodo_id', periodoActivo.id_periodo);
    pushLog(`✅ Periodo activo guardado: ID ${periodoActivo.id_periodo}`);

    return { success: true, log };

  } catch (error) {
    const errorMsg = error.response
      ? `HTTP ${error.response.status}: ${JSON.stringify(error.response.data)}`
      : error.message;
    pushLog(`❌ FALLO: ${errorMsg}`);
    return { success: false, log, error: errorMsg };
  }
};

module.exports = { runAdminScenario };
