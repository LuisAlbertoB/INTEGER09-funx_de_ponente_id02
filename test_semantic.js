const nlpClient = require('./src/services/nlp.client');
const catalogoService = require('./src/services/catalogo.service');

async function test() {
  console.log("Indexando...");
  await nlpClient.indexarEvento(100, "Curso avanzado de React", "Aprende hooks, state y context.");
  
  setTimeout(async () => {
    console.log("Buscando 'programacion web'...");
    const results = await catalogoService.getEventos(1, 10, {buscar: "programacion web"});
    console.log("Resultados:", JSON.stringify(results.datos.map(d => d.titulo), null, 2));
    process.exit(0);
  }, 2000);
}

test();
