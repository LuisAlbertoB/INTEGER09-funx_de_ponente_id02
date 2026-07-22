'use strict';

/**
 * ╔══════════════════════════════════════════════════════════════════════════╗
 * ║           UniEvents — Emulador de Comportamiento de la App Móvil        ║
 * ║                        seed_massive.js  v2.0                            ║
 * ╠══════════════════════════════════════════════════════════════════════════╣
 * ║  Este script emula fielmente el flujo de la app Flutter, comunicándose  ║
 * ║  EXCLUSIVAMENTE con el API REST del servidor en producción.              ║
 * ║                                                                          ║
 * ║  FLUJO:                                                                  ║
 * ║    FASE 0 — Preparación (login admin, leer CSV, obtener catálogos)       ║
 * ║    FASE 1 — Crear 5 Usuarios Ponentes                                    ║
 * ║    FASE 2 — Cada ponente crea 5 Conferencias → 25 conferencias totales   ║
 * ║    FASE 3 — Crear 10 Usuarios Participantes                              ║
 * ║    FASE 4 — Cada participante crea 10 Reportes → 100 reportes totales    ║
 * ║    FASE 5 — Cada participante comenta 2 veces en cada conferencia        ║
 * ║    FASE 6 — Cada participante evalúa cada conferencia (1 vez c/u)        ║
 * ╚══════════════════════════════════════════════════════════════════════════╝
 */

const fs   = require('fs');
const csv  = require('csv-parser');
const axios = require('axios');

// ── Configuración ──────────────────────────────────────────────────────────
const BASE_URL       = 'http://3.226.156.228';
const CSV_FILE       = './data/reviews_traducidas.csv';
const ADMIN_MATRICULA = '000000';
const ADMIN_PASS      = 'admin1';
const USER_PASS       = 'contraseña';   // Contraseña unificada para todos los usuarios del script

// Contadores de matrículas (se usarán secuencialmente)
const PONENTE_MATRICULA_START     = 20000;
const PARTICIPANTE_MATRICULA_START = 30000;

// ── Temáticas de conferencias universitarias (15 plantillas, se rotan) ─────
const TEMAS_CONFERENCIAS = [
  { titulo: 'Fundamentos de Ingeniería de Software Ágil',        tematica: 'tecnología',             nivel: 'undergraduate' },
  { titulo: 'Industria 4.0: Automatización y Robótica',           tematica: 'industria',              nivel: 'postgraduate' },
  { titulo: 'Plan de Negocios para Startups Tecnológicas',        tematica: 'negocios',               nivel: 'ambos' },
  { titulo: 'Becas Nacionales e Internacionales 2025',            tematica: 'becas y financiamiento', nivel: 'ambos' },
  { titulo: 'Panorama de Carreras en TI y Empleabilidad',         tematica: 'orientación profesional',nivel: 'ambos' },
  { titulo: 'Inteligencia Artificial Aplicada a la Salud',        tematica: 'tecnología',             nivel: 'postgraduate' },
  { titulo: 'Desarrollo Web Full-Stack con Node.js y React',      tematica: 'tecnología',             nivel: 'undergraduate' },
  { titulo: 'Sostenibilidad y Gestión Ambiental Empresarial',     tematica: 'medio ambiente',         nivel: 'ambos' },
  { titulo: 'Emprendimiento Social en Comunidades Rurales',        tematica: 'negocios',               nivel: 'ambos' },
  { titulo: 'Ciberseguridad y Protección de Datos Personales',    tematica: 'tecnología',             nivel: 'postgraduate' },
  { titulo: 'Diseño UX/UI para Aplicaciones Móviles',             tematica: 'diseño',                 nivel: 'ambos' },
  { titulo: 'Matemáticas Financieras y Análisis de Inversión',    tematica: 'finanzas',               nivel: 'postgraduate' },
  { titulo: 'Liderazgo y Habilidades Directivas para Jóvenes',    tematica: 'desarrollo personal',    nivel: 'ambos' },
  { titulo: 'Ciencia de Datos y Visualización con Python',        tematica: 'tecnología',             nivel: 'undergraduate' },
  { titulo: 'Logística y Cadena de Suministro Global',            tematica: 'industria',              nivel: 'postgraduate' },
];

// Títulos base para reportes de infraestructura
const TITULOS_REPORTES = [
  'Aire acondicionado no funciona',
  'Proyector sin imagen',
  'Sillas en mal estado',
  'Ventana rota',
  'Falla de internet en el aula',
  'Iluminación deficiente',
  'Pizarrón rayado e ilegible',
  'Puerta con cerradura dañada',
  'Cañón desconectado',
  'Mesa dañada en el laboratorio',
];

// ── Utilidades ─────────────────────────────────────────────────────────────
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

const log = {
  info:    (msg) => console.log(`  ℹ️  ${msg}`),
  ok:      (msg) => console.log(`  ✅ ${msg}`),
  err:     (msg) => console.log(`  ❌ ${msg}`),
  section: (msg) => console.log(`\n${'═'.repeat(60)}\n  ${msg}\n${'═'.repeat(60)}`),
  dot:     (char) => process.stdout.write(char),
};

/** Hace login y retorna el token. */
const login = async (matricula, contrasena) => {
  const res = await axios.post(`${BASE_URL}/api/auth/login`, { matricula, contrasena });
  return { token: res.data.token, usuario: res.data.usuario };
};

/** Crea un usuario vía Admin y devuelve su token. */
const crearUsuarioYLoguear = async (adminToken, payload) => {
  const { nombre_completo, matricula, contrasena, rol } = payload;
  try {
    await axios.post(
      `${BASE_URL}/api/usuarios`,
      { nombre_completo, matricula, contrasena, rol },
      { headers: { Authorization: `Bearer ${adminToken}` } }
    );
  } catch (e) {
    // Si ya existe (409) continuamos; otros errores los propagamos
    if (e.response?.status !== 409) throw e;
    log.info(`Usuario ${matricula} ya existía, se reutiliza.`);
  }

  const { token, usuario } = await login(matricula, contrasena);
  return { ...usuario, matricula, contrasena, token, rol };
};

/** Lee el CSV y retorna un array mezclado de filas. */
const leerCSV = () => new Promise((resolve, reject) => {
  const rows = [];
  fs.createReadStream(CSV_FILE)
    .pipe(csv())
    .on('data', (row) => {
      if (row.review_es && row.rating_norm) rows.push(row);
    })
    .on('end', () => resolve(rows.sort(() => 0.5 - Math.random())))
    .on('error', reject);
});

// Cursor global del CSV (avanza por todas las fases para no repetir texto)
let csvCursor = 0;
let dataset = [];

const nextRow = () => {
  if (csvCursor >= dataset.length) csvCursor = 0;
  return dataset[csvCursor++];
};

/** Trunca un texto a maxLen caracteres sin cortar palabras. */
const truncar = (texto, maxLen = 400) => {
  if (!texto || texto.length <= maxLen) return texto;
  return texto.substring(0, maxLen).replace(/\s\S*$/, '') + '...';
};

// ══════════════════════════════════════════════════════════════════════════
//  SCRIPT PRINCIPAL
// ══════════════════════════════════════════════════════════════════════════
async function runSeeder() {

  // ────────────────────────────────────────────────────────────────────────
  // FASE 0 — Preparación
  // ────────────────────────────────────────────────────────────────────────
  log.section('FASE 0 — Preparación del entorno');

  // 0.1 — Login Admin
  log.info('Autenticando como Administrador...');
  let adminToken;
  try {
    const { token } = await login(ADMIN_MATRICULA, ADMIN_PASS);
    adminToken = token;
    log.ok('Token de administrador obtenido.');
  } catch (e) {
    log.err(`Login admin falló: ${e.response?.data?.message || e.message}`);
    process.exit(1);
  }

  const authAdmin = { headers: { Authorization: `Bearer ${adminToken}` } };

  // 0.2 — Leer CSV
  log.info(`Leyendo dataset: ${CSV_FILE}...`);
  try {
    dataset = await leerCSV();
    log.ok(`${dataset.length} reseñas en español cargadas y mezcladas.`);
  } catch (e) {
    log.err(`Error leyendo CSV: ${e.message}`);
    process.exit(1);
  }

  // 0.3 — Obtener ID de actividad "Conferencia" desde el servidor
  log.info('Consultando catálogo de actividades al servidor...');
  let idActividadConferencia;
  let idsAulas = [];
  try {
    const resActs = await axios.get(`${BASE_URL}/api/actividades`, authAdmin);
    const conferencias = resActs.data.filter(a => a.titulo_actividad === 'Conferencia');
    if (conferencias.length === 0) throw new Error('No se encontraron actividades tipo "Conferencia".');
    idActividadConferencia = conferencias[0].id_actividad;
    log.ok(`Usando id_actividad = ${idActividadConferencia} (Conferencia).`);

    const resAulas = await axios.get(`${BASE_URL}/api/aulas`, authAdmin);
    idsAulas = resAulas.data.map(a => a.id_aula);
    log.ok(`${idsAulas.length} aulas disponibles encontradas.`);
  } catch (e) {
    log.err(`Error consultando catálogos: ${e.response?.data?.message || e.message}`);
    process.exit(1);
  }

  // ────────────────────────────────────────────────────────────────────────
  // FASE 1 — Crear 5 Usuarios Ponentes
  // ────────────────────────────────────────────────────────────────────────
  log.section('FASE 1 — Creando 5 Usuarios Ponentes');

  const NOMBRES_PONENTES = [
    'Dr. Carlos Mendoza Torres',
    'Ing. Ana Ramírez Gutiérrez',
    'Mtro. José Luis Hernández Vega',
    'Dra. María Fernanda López Cruz',
    'Ing. Roberto Sánchez Morales',
  ];

  const ponentes = [];
  for (let i = 0; i < 5; i++) {
    const matricula = (PONENTE_MATRICULA_START + i).toString();
    try {
      const usuario = await crearUsuarioYLoguear(adminToken, {
        nombre_completo: NOMBRES_PONENTES[i],
        matricula,
        contrasena: USER_PASS,
        rol: 'ponente',
      });
      ponentes.push(usuario);
      log.dot('👨‍🏫');
    } catch (e) {
      log.err(`Ponente ${matricula}: ${e.response?.data?.message || e.message}`);
    }
  }
  console.log('');
  log.ok(`${ponentes.length}/5 ponentes creados y autenticados.`);

  // ────────────────────────────────────────────────────────────────────────
  // FASE 2 — Cada ponente crea 5 Conferencias
  // ────────────────────────────────────────────────────────────────────────
  log.section('FASE 2 — Creando 25 Conferencias (5 por ponente)');

  const conferenceIds = []; // ← Array persistente de IDs de conferencias creadas

  let temaIndex = 0;
  for (const ponente of ponentes) {
    log.info(`Ponente: ${ponente.nombre_completo} (${ponente.matricula})`);
    for (let j = 0; j < 5; j++) {
      const tema = TEMAS_CONFERENCIAS[temaIndex % TEMAS_CONFERENCIAS.length];
      temaIndex++;
      const row = nextRow();
      const descripcion = truncar(row.review_es, 450);

      try {
        const res = await axios.post(
          `${BASE_URL}/api/eventos`,
          {
            titulo: tema.titulo,
            descripcion,
            tematica: tema.tematica,
            nivel_academico_objetivo: tema.nivel,
            id_actividad: idActividadConferencia,
          },
          { headers: { Authorization: `Bearer ${ponente.token}` } }
        );
        const idConf = res.data.evento?.id_conferencia;
        if (idConf) conferenceIds.push(idConf);
        log.dot('📅');
        await sleep(200); // Pausa para no saturar el motor FAISS
      } catch (e) {
        log.err(`Evento de ${ponente.matricula}: ${e.response?.data?.message || e.message}`);
      }
    }
    console.log('');
  }
  log.ok(`${conferenceIds.length}/25 conferencias creadas. IDs: [${conferenceIds.join(', ')}]`);

  if (conferenceIds.length === 0) {
    log.err('No se creó ninguna conferencia. Abortando fases siguientes que dependen de los IDs.');
    process.exit(1);
  }

  // ────────────────────────────────────────────────────────────────────────
  // FASE 3 — Crear 10 Usuarios Participantes
  // ────────────────────────────────────────────────────────────────────────
  log.section('FASE 3 — Creando 10 Usuarios Participantes (Generales)');

  const NOMBRES_PARTICIPANTES = [
    'Sofía Villareal Orozco',
    'Diego Castillo Reyes',
    'Valeria Moreno Jiménez',
    'Andrés Ruiz Salinas',
    'Isabella Torres Medina',
    'Miguel Ángel Flores Paredes',
    'Camila Vargas Espinoza',
    'Luis Eduardo Pérez Núñez',
    'Daniela Ríos Contreras',
    'Fernando Delgado Aguilar',
  ];

  const participantes = [];
  for (let i = 0; i < 10; i++) {
    const matricula = (PARTICIPANTE_MATRICULA_START + i).toString();
    try {
      const usuario = await crearUsuarioYLoguear(adminToken, {
        nombre_completo: NOMBRES_PARTICIPANTES[i],
        matricula,
        contrasena: USER_PASS,
        rol: 'participante',
      });
      participantes.push(usuario);
      log.dot('🎓');
    } catch (e) {
      log.err(`Participante ${matricula}: ${e.response?.data?.message || e.message}`);
    }
  }
  console.log('');
  log.ok(`${participantes.length}/10 participantes creados y autenticados.`);

  // ────────────────────────────────────────────────────────────────────────
  // FASE 4 — Cada participante crea 10 Reportes de Incidencia
  // ────────────────────────────────────────────────────────────────────────
  log.section('FASE 4 — Creando 100 Reportes de Incidencia (10 por participante)');

  let reportesCount = 0;
  for (const participante of participantes) {
    log.info(`Reportes de ${participante.nombre_completo}...`);
    for (let k = 0; k < 10; k++) {
      const row = nextRow();
      const tituloReporte = TITULOS_REPORTES[k % TITULOS_REPORTES.length];
      const descripcionReporte = `${truncar(row.review_es, 200)} Incidencia específica: ${tituloReporte}.`;
      const idAula = idsAulas[k % idsAulas.length];

      try {
        await axios.post(
          `${BASE_URL}/api/reportes`,
          { titulo: tituloReporte, descripcion: descripcionReporte, id_aula: idAula },
          { headers: { Authorization: `Bearer ${participante.token}` } }
        );
        reportesCount++;
        log.dot('🛠️');
        await sleep(150); // Pausa para el motor NER en segundo plano
      } catch (e) {
        log.err(`Reporte de ${participante.matricula}: ${e.response?.data?.message || e.message}`);
      }
    }
    console.log('');
  }
  log.ok(`${reportesCount}/100 reportes creados.`);

  // ────────────────────────────────────────────────────────────────────────
  // FASE 5 — Cada participante comenta 2 veces en cada conferencia
  // ────────────────────────────────────────────────────────────────────────
  log.section('FASE 5 — Publicando Comentarios en el Foro (2 por conf/user)');
  log.info(`Total esperado: ${participantes.length} users × ${conferenceIds.length} confs × 2 = ${participantes.length * conferenceIds.length * 2} comentarios`);

  let comentariosCount = 0;
  for (const participante of participantes) {
    process.stdout.write(`  [${participante.nombre_completo}] `);
    for (const idConf of conferenceIds) {
      for (let c = 0; c < 2; c++) {
        const row = nextRow();
        // Mensaje natural corto (máx 200 chars para simular un comentario de app)
        const mensaje = truncar(row.review_es, 200);

        try {
          await axios.post(
            `${BASE_URL}/api/eventos/${idConf}/foro`,
            { mensaje },
            { headers: { Authorization: `Bearer ${participante.token}` } }
          );
          comentariosCount++;
          log.dot('💬');
        } catch (e) {
          log.err(`Foro conf#${idConf} user ${participante.matricula}: ${e.response?.data?.message || e.message}`);
        }
      }
    }
    console.log('');
  }
  log.ok(`${comentariosCount} comentarios publicados en el foro.`);

  // ────────────────────────────────────────────────────────────────────────
  // FASE 6 — Cada participante evalúa cada conferencia (1 vez)
  // ────────────────────────────────────────────────────────────────────────
  log.section('FASE 6 — Enviando Evaluaciones y Autoevaluaciones');
  log.info(`Total esperado: ${participantes.length} users × ${conferenceIds.length} confs = ${participantes.length * conferenceIds.length} evaluaciones`);

  let evaluacionesCount = 0;
  for (const participante of participantes) {
    process.stdout.write(`  [${participante.nombre_completo}] `);
    for (const idConf of conferenceIds) {
      const row = nextRow();
      // Derivar calificación (1–5) desde rating_norm (0.0–1.0)
      const ratingNorm = parseFloat(row.rating_norm || 0.7);
      const calificacion = Math.max(1, Math.min(5, Math.round(ratingNorm * 5)));
      const porcentaje   = calificacion * 20;
      const comentario   = truncar(row.review_es, 180);

      try {
        await axios.post(
          `${BASE_URL}/api/eventos/${idConf}/evaluacion`,
          {
            calificacion,
            porcentaje_satisfaccion: porcentaje,
            comentario_escrito: comentario,
          },
          { headers: { Authorization: `Bearer ${participante.token}` } }
        );
        evaluacionesCount++;
        log.dot('⭐');
        await sleep(100); // Pausa para motor de sentimiento NLP
      } catch (e) {
        // P2002 = ya evaluó este evento (unique constraint) → ignorar silenciosamente
        if (e.response?.status !== 409) {
          log.err(`Eval conf#${idConf} user ${participante.matricula}: ${e.response?.data?.message || e.message}`);
        }
      }
    }
    console.log('');
  }
  log.ok(`${evaluacionesCount} evaluaciones enviadas (dispara análisis de sentimiento NLP).`);

  // ────────────────────────────────────────────────────────────────────────
  // RESUMEN FINAL
  // ────────────────────────────────────────────────────────────────────────
  log.section('🎉 EMULACIÓN COMPLETADA 🎉');
  console.log(`
  ┌─────────────────────────────────────────────┐
  │  Resumen de datos inyectados                │
  ├─────────────────────────────────────────────┤
  │  Ponentes creados       : ${String(ponentes.length).padEnd(18)}│
  │  Conferencias creadas   : ${String(conferenceIds.length).padEnd(18)}│
  │  Participantes creados  : ${String(participantes.length).padEnd(18)}│
  │  Reportes de incidencia : ${String(reportesCount).padEnd(18)}│
  │  Comentarios en foro    : ${String(comentariosCount).padEnd(18)}│
  │  Evaluaciones enviadas  : ${String(evaluacionesCount).padEnd(18)}│
  └─────────────────────────────────────────────┘

  Próximos pasos de verificación:
  1. Abrir la App Flutter → "Explorar Catálogo IA" (debe mostrar las ${conferenceIds.length} conferencias)
  2. Admin → "Reportes (IA)" → El clustering de ${reportesCount} reportes debe agruparse
  3. "Para Ti (IA)" → Las recomendaciones deben aparecer para cualquier participante
  `);
}

runSeeder().catch((err) => {
  console.error('\n\n💥 ERROR FATAL NO CAPTURADO:', err.message);
  process.exit(1);
});
