require('dotenv').config();
const nlpClient = require('./src/services/nlp.client');
const eventosService = require('./src/services/eventos.service');
const reportesService = require('./src/services/reportes.service');
const prisma = require('./src/prismaClient');

async function test() {
  console.log("=== Test NLP Recomender ===");
  try {
    // 1. Agregar eventos de prueba a NLP para que pueda recomendar algo (por si la DB de FAISS esta vacia o diferente)
    await nlpClient.indexarEvento(200, "Node.js para Backend", "Creacion de APIs REST con Express y Node.");
    await nlpClient.indexarEvento(201, "Aprende React 18", "Taller completo sobre Frontend, Hooks y Context.");
    await nlpClient.indexarEvento(202, "Guitarra Acústica", "Clases basicas de guitarra para principiantes.");
    
    // 2. Simulamos que el usuario tiene evaluaciones
    // Insertaremos en DB real si no existen
    const user_id = 1; // Usaremos usuario 1 (admin)
    try {
        await prisma.evaluacionEvento.createMany({
            data: [
                { id_usuario: user_id, id_evento: 200, calificacion: 5, porcentaje_satisfaccion: 100 }
            ],
            skipDuplicates: true
        });
    } catch(e) {}

    const recs = await eventosService.getRecomendaciones(user_id);
    console.log(`Recomendaciones para User ${user_id}:`);
    recs.forEach(r => console.log(`- ID: ${r.id_conferencia} | Score: ${r.ai_score} | Titulo: ${r.titulo}`));

  } catch (error) {
    console.error("Error en Recomendaciones:", error);
  }

  console.log("\n=== Test NLP Clustering ===");
  try {
    // Asegurar reportes en la BD
    try {
        await prisma.reporte.createMany({
            data: [
                { id_user_reportante: 1, id_aula: 1, id_periodo: 1, titulo: 'Falla AC', descripcion: 'El aire acondicionado echa aire caliente' },
                { id_user_reportante: 1, id_aula: 2, id_periodo: 1, titulo: 'Problema ventilación', descripcion: 'El AC no sirve y hace calor' },
                { id_user_reportante: 1, id_aula: 3, id_periodo: 1, titulo: 'Silla rota', descripcion: 'A la silla del maestro le falta una pata' },
                { id_user_reportante: 1, id_aula: 4, id_periodo: 1, titulo: 'Luz parpadea', descripcion: 'El proyector no enciende por la luz' }
            ],
            skipDuplicates: true
        });
    } catch(e) {}

    const clusters = await reportesService.getClusteringReportes();
    console.log(`Total clusters formados: ${clusters.total_clusters}`);
    clusters.grupos.forEach(g => {
       console.log(`- Cluster ${g.cluster_id}: ${g.reportes.map(r => r.titulo).join(', ')}`);
    });

  } catch (error) {
    console.error("Error en Clustering:", error);
  }

  process.exit(0);
}

test();
