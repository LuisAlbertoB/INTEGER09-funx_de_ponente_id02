require('dotenv').config();
const prisma = require('./src/prismaClient');

async function test() {
  const evaluaciones = await prisma.evaluacionEvento.findMany({
    where: { id_usuario: 1 },
    select: { id_evento: true }
  });
  console.log("Historial del usuario 1:", evaluaciones.map(e => e.id_evento));
  process.exit(0);
}

test();
