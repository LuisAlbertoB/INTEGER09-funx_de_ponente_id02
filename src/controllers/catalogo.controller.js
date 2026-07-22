const prisma = require('../prismaClient');

const findEspaciosPaginados = async (skip, take, filtros) => {
  const where = { estado: 1, ...filtros }; // Solo espacios activos
  
  const [totalRegistros, espacios] = await prisma.$transaction([
    prisma.aula.count({ where }),
    prisma.aula.findMany({
      where,
      skip,
      take,
      include: {
        edificio: { select: { nombre_clave: true } },
        owner: { select: { nombre_completo: true } }
      },
      orderBy: { nombre_clave: 'asc' }
    })
  ]);

  return { totalRegistros, espacios };
};

const findEventosPaginados = async (skip, take, filtros) => {
  const where = { estado: 1, ...filtros }; // Solo eventos activos
  
  const [totalRegistros, eventos] = await prisma.$transaction([
    prisma.conferencia.count({ where }),
    prisma.conferencia.findMany({
      where,
      skip,
      take,
      include: {
        ponente: { select: { nombre_completo: true } },
        actividad: { select: { titulo_actividad: true } }
      },
      orderBy: { createdAt: 'desc' }
    })
  ]);

  return { totalRegistros, eventos };
};

module.exports = {
  findEspaciosPaginados,
  findEventosPaginados
};
