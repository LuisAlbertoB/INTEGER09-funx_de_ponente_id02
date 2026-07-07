const fs = require('fs');
const csv = require('csv-parser');
const axios = require('axios');

const BASE_URL = 'http://3.226.156.228';
const CSV_FILE = './data/collegereview2021.csv';
const ADMIN_MATRICULA = '000000';
const ADMIN_PASS = 'admin1';

// Configuraciones
const NUM_USERS = 50;
const NUM_EVENTS = 40;
const NUM_REPORTS = 50;

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function runSeeder() {
  console.log('=== Iniciando Inyección Masiva de Datos NLP ===');
  console.log(`Target: ${BASE_URL}\n`);

  // 1. Obtener Token Admin
  console.log('1. Autenticando como Admin...');
  let adminToken = '';
  try {
    const loginRes = await axios.post(`${BASE_URL}/api/auth/login`, {
      matricula: ADMIN_MATRICULA,
      contrasena: ADMIN_PASS
    });
    adminToken = loginRes.data.token;
    console.log('✅ Admin Token obtenido.\n');
  } catch (err) {
    console.error('❌ Error al hacer login admin:', err.response?.data || err.message);
    return;
  }

  // 2. Leer CSV
  console.log('2. Leyendo y parseando Dataset de Kaggle (collegereview2021.csv)...');
  const dataset = [];
  await new Promise((resolve, reject) => {
    fs.createReadStream(CSV_FILE)
      .pipe(csv())
      .on('data', (data) => {
        if (data.Name && data.review && data.rating) {
          dataset.push(data);
        }
      })
      .on('end', resolve)
      .on('error', reject);
  });
  console.log(`✅ ${dataset.length} registros cargados del CSV.\n`);

  // Shuffle dataset
  dataset.sort(() => 0.5 - Math.random());

  // 3. Crear Usuarios (Mitad Ponentes, Mitad Alumnos)
  console.log(`3. Inyectando ${NUM_USERS} Usuarios Sintéticos...`);
  const createdUsers = []; // { id_usuario, matricula, contrasena, rol, token }
  let matriculaCounter = 10000;

  for (let i = 0; i < NUM_USERS; i++) {
    const row = dataset[i];
    const rol = i < (NUM_USERS * 0.3) ? 'ponente' : 'participante'; // 30% ponentes, 70% participante
    const matricula = (matriculaCounter + i).toString();
    const contrasena = 'pass123';
    
    try {
      await axios.post(`${BASE_URL}/api/usuarios`, {
        nombre_completo: row.Name.trim() || `User ${matricula}`,
        matricula: matricula,
        contrasena: contrasena,
        rol: rol
      }, { headers: { Authorization: `Bearer ${adminToken}` } });
    } catch (e) {
      // Si ya existe, ignoramos el error y procedemos a hacer login
    }

    try {
      // Iniciar sesión para obtener el token de este usuario
      const loginRes = await axios.post(`${BASE_URL}/api/auth/login`, { matricula, contrasena });
      
      createdUsers.push({
        ...loginRes.data.usuario,
        matricula,
        contrasena,
        token: loginRes.data.token,
        rol
      });
      process.stdout.write('👤');
    } catch (e) {
      console.error('\n❌ Error al loguear usuario', matricula, e.response?.data?.message || e.message);
    }
  }
  console.log(`\n✅ ${createdUsers.length} Usuarios creados y logueados.\n`);

  // 4. Crear Eventos (usando usuarios 'ponente')
  console.log(`4. Inyectando ${NUM_EVENTS} Eventos Semánticos (Activando Motor FAISS)...`);
  const ponentes = createdUsers.filter(u => u.rol === 'ponente');
  const participantes = createdUsers.filter(u => u.rol === 'participante');
  const createdEvents = [];

  let datasetCursor = NUM_USERS; // Seguir leyendo donde nos quedamos

  for (let i = 0; i < NUM_EVENTS; i++) {
    if (datasetCursor >= dataset.length) datasetCursor = 0;
    const row = dataset[datasetCursor++];
    const ponente = ponentes[i % ponentes.length];

    // Obtener actividades y aulas validas
    const id_actividad = (i % 5) + 1; // Asumimos IDs 1 al 5
    const id_aula = (i % 8) + 1; // Asumimos aulas 1 al 8
    const id_periodo = 1;

    // Limpiar review para usarla como descripción
    let desc = row.review.replace(/(\r\n|\n|\r)/gm, " ").trim();
    if (desc.length > 500) desc = desc.substring(0, 500) + '...';

    // Construir un título corto basado en las primeras palabras
    let titulo = desc.split(' ').slice(0, 4).join(' ').replace(/[^a-zA-Z0-9 ]/g, '') + '...';

    try {
      const evRes = await axios.post(`${BASE_URL}/api/eventos`, {
        titulo: titulo,
        descripcion: desc,
        id_actividad: id_actividad,
        id_aula: id_aula,
        id_periodo: id_periodo,
        fecha: new Date(Date.now() + Math.random() * 864000000).toISOString(),
        hora_inicio: "10:00:00",
        hora_fin: "12:00:00",
        estado: 1
      }, { headers: { Authorization: `Bearer ${ponente.token}` } });
      
      createdEvents.push(evRes.data.evento);
      process.stdout.write('📅');
      await sleep(150); // Pequeña pausa para no saturar al NLP de golpe
    } catch (e) {
      console.error('\n❌ Error creando evento:', e.response?.data?.message || e.message);
    }
  }
  console.log(`\n✅ ${createdEvents.length} Eventos procesados y vectorizados por la IA.\n`);

  // 5. Crear Evaluaciones (Motor de Recomendaciones)
  console.log(`5. Generando Evaluaciones Cruzadas (Entrenando Recomendador)...`);
  let evalCount = 0;
  for (const participante of participantes) {
    // Cada participante evalúa 5 eventos aleatorios
    const eventosAEvaluar = [...createdEvents].sort(() => 0.5 - Math.random()).slice(0, 5);
    
    for (const ev of eventosAEvaluar) {
      if (datasetCursor >= dataset.length) datasetCursor = 0;
      const row = dataset[datasetCursor++];
      let rating = parseFloat(row.rating || 5);
      if (rating > 5) rating = rating / 2; // Normalizar a 5 si venía en base 10
      const calificacion = Math.max(1, Math.min(5, Math.round(rating)));

      try {
        await axios.post(`${BASE_URL}/api/eventos/${ev.id_conferencia}/evaluacion`, {
          calificacion: calificacion,
          porcentaje_satisfaccion: calificacion * 20,
          comentario_escrito: row.review.substring(0, 100)
        }, { headers: { Authorization: `Bearer ${participante.token}` } });
        evalCount++;
        if (evalCount % 10 === 0) process.stdout.write('⭐');
      } catch (e) {
        // Ignorar si ya evaluó
      }
    }
  }
  console.log(`\n✅ ${evalCount} Evaluaciones inyectadas.\n`);

  // 6. Crear Reportes de Mantenimiento (Clustering IA)
  console.log(`6. Simulando ${NUM_REPORTS} Reportes de Mantenimiento (Topic Modeling)...`);
  const categorias = ["Aire Acondicionado roto", "Proyector no enciende", "Sillas quebradas", "Ventana rota", "Falla de internet"];
  let reportesCount = 0;

  for (let i = 0; i < NUM_REPORTS; i++) {
    if (datasetCursor >= dataset.length) datasetCursor = 0;
    const row = dataset[datasetCursor++];
    const reporter = createdUsers[i % createdUsers.length];
    
    const titulo = categorias[i % categorias.length];
    let desc = row.review.substring(0, 150) + `... Mi queja principal es sobre: ${titulo}.`;

    try {
      await axios.post(`${BASE_URL}/api/reportes`, {
        titulo: titulo,
        descripcion: desc,
        id_aula: (i % 8) + 1
      }, { headers: { Authorization: `Bearer ${reporter.token}` } });
      reportesCount++;
      if (reportesCount % 5 === 0) process.stdout.write('🛠️');
      await sleep(100); // Pausa para la extracción de NER/Sentimientos
    } catch (e) {
      console.error('\n❌ Error reporte:', e.response?.data?.message || e.message);
    }
  }
  console.log(`\n✅ ${reportesCount} Reportes de infraestructura procesados por IA.\n`);

  console.log('=== 🎉 INYECCIÓN MASIVA FINALIZADA 🎉 ===');
  console.log(`Prueba las funciones de Clustering y Recomendaciones en tu Flutter App.`);
}

runSeeder().catch(console.error);
