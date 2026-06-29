const authClient = require('../../services/apiClients/auth.client');
const espaciosClient = require('../../services/apiClients/espacios.client');
const eventosClient = require('../../services/apiClients/eventos.client');
const StateStore = require('../../store/StateStore');

const runMarketplaceScenario = async () => {
  const log = [];
  const pushLog = (msg) => {
    console.log(msg);
    log.push({ time: new Date(), message: msg });
  };

  try {
    // 1. Login Ponente (Dueño del espacio)
    pushLog('1. Autenticando Ponente (Dueño)...');
    // NOTA: Usar credenciales reales o de semilla de la DB de prueba
    await authClient.login('21300001', 'password123', 'ponente_token');
    StateStore.set('active_token', StateStore.get('ponente_token'));
    pushLog('✅ Ponente autenticado.');

    // 2. Crear Espacio
    pushLog('2. Creando nuevo Espacio (Aula)...');
    const espacio = await espaciosClient.createEspacio({
      nombre_clave: `Lab Test ${Date.now()}`,
      id_edificio: 1 // Asegurarse que exista el edificio 1 en la DB objetivo
    });
    StateStore.set('last_espacio_id', espacio.espacio.id_aula);
    pushLog(`✅ Espacio creado con ID: ${espacio.espacio.id_aula}`);

    // 3. Login Event Manager
    pushLog('3. Autenticando Event Manager (Coordinador)...');
    await authClient.login('21300003', 'password123', 'coordinador_token');
    StateStore.set('active_token', StateStore.get('coordinador_token'));
    pushLog('✅ Coordinador autenticado.');

    // 4. Crear Evento
    pushLog('4. Creando Evento Borrador...');
    const evento = await eventosClient.createEvento({
      titulo: `Conferencia AI Test ${Date.now()}`,
      descripcion: 'Evento de prueba end-to-end',
      id_actividad: 1 // Asegurarse que exista actividad 1
    });
    StateStore.set('last_evento_id', evento.evento.id_conferencia);
    pushLog(`✅ Evento creado con ID: ${evento.evento.id_conferencia}`);

    // 5. Solicitar el Espacio
    pushLog('5. Solicitando Espacio para el Evento...');
    const solicitud = await eventosClient.solicitarEspacio(
      evento.evento.id_conferencia, 
      espacio.espacio.id_aula,
      {
        fecha_inicio: new Date().toISOString(),
        fecha_final: new Date(Date.now() + 3600000).toISOString(),
        motivo: 'Test Machine Automation'
      }
    );
    StateStore.set('last_solicitud_id', solicitud.solicitud.id_solicitud);
    pushLog(`✅ Solicitud creada con ID: ${solicitud.solicitud.id_solicitud}`);

    // 6. Ponente aprueba la solicitud
    pushLog('6. Cambiando al Ponente para aprobar solicitud...');
    StateStore.set('active_token', StateStore.get('ponente_token'));
    await espaciosClient.aprobarSolicitud(solicitud.solicitud.id_solicitud);
    pushLog('✅ Solicitud Aprobada por el Ponente.');

    // 7. Login Alumno y Evaluar
    pushLog('7. Autenticando Alumno...');
    await authClient.login('21300005', 'password123', 'alumno_token'); // Asumiendo matrícula de participante
    StateStore.set('active_token', StateStore.get('alumno_token'));
    pushLog('✅ Alumno autenticado.');
    
    pushLog('8. Alumno evaluando evento...');
    await eventosClient.submitEvaluacion(evento.evento.id_conferencia, {
      calificacion: 5.0,
      porcentaje_satisfaccion: 100,
      comentario_escrito: '¡Excelente evento! Test E2E aprobado.'
    });
    pushLog('✅ Evaluación enviada con éxito.');

    return { success: true, log };

  } catch (error) {
    const errorMsg = error.response ? JSON.stringify(error.response.data) : error.message;
    pushLog(`❌ ERROR en el escenario: ${errorMsg}`);
    return { success: false, log, error: errorMsg };
  }
};

module.exports = {
  runMarketplaceScenario
};
