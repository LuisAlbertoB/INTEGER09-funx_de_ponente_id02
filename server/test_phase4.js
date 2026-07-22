const nlpClient = require('./src/services/nlp.client');
const eventosService = require('./src/services/eventos.service');
const reportesService = require('./src/services/reportes.service');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function test() {
  console.log("=== Test NLP Recomender ===");
  // Creamos algunas evaluaciones falsas para el usuario 1
  try {
    await prisma.evaluacionEvento.createMany({
        data: [
            { calificacion: 5, id_evento: 10, id_usuario: 1, porcentaje_satisfaccion: 100 },
            { calificacion: 4, id_evento: 11, id_usuario: 1, porcentaje_satisfaccion: 90 }
        ],
        skipDuplicates: true
    });
  } catch(e) {}
  
  const recs = await eventosService.getRecomendaciones(1);
  console.log("Recomendaciones para User 1:", JSON.stringify(recs.map(r => r.titulo), null, 2));

  console.log("\n=== Test NLP Clustering ===");
  // Creamos algunos reportes falsos
  try {
    await prisma.reporte.createMany({
        data: [
            { id_user_reportante: 1, id_aula: 1, titulo: 'Falla AC', descripcion: 'Aire caliente' },
            { id_user_reportante: 1, id_aula: 1, titulo: 'Ventilación', descripcion: 'El AC no sirve' },
            { id_user_reportante: 1, id_aula: 1, titulo: 'Silla', descripcion: 'Rota' }
        ],
        skipDuplicates: true
    });
  } catch(e) {}

  const clusters = await reportesService.getClusteringReportes();
  console.log(`Total clusters: ${clusters.total_clusters}`);
  clusters.grupos.forEach(g => {
     console.log(`Cluster ${g.cluster_id}: ${g.reportes.map(r => r.titulo).join(', ')}`);
  });

  process.exit(0);
}

test();
