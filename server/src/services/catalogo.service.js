const catalogoCtrl = require('../controllers/catalogo.controller');

const buildMeta = (totalRegistros, page, limit) => {
  return {
    totalRegistros,
    paginaActual: page,
    paginasTotales: Math.ceil(totalRegistros / limit)
  };
};

const getEspacios = async (page = 1, limit = 10, filtrosQuery = {}) => {
  const skip = (page - 1) * limit;
  const take = limit;
  
  // Construir filtros simples si es necesario (ej. búsqueda por nombre)
  const filtros = {};
  if (filtrosQuery.buscar) {
    filtros.nombre_clave = { contains: filtrosQuery.buscar, mode: 'insensitive' };
  }

  const { totalRegistros, espacios } = await catalogoCtrl.findEspaciosPaginados(skip, take, filtros);
  const meta = buildMeta(totalRegistros, page, limit);

  return { meta, datos: espacios };
};

const getEventos = async (page = 1, limit = 10, filtrosQuery = {}) => {
  const skip = (page - 1) * limit;
  const take = limit;
  const nlpClient = require('../services/nlp.client');

  const filtros = {};
  if (filtrosQuery.tematica) {
    filtros.tematica = { contains: filtrosQuery.tematica, mode: 'insensitive' };
  }

  // Si hay consulta de búsqueda libre, usar Búsqueda Semántica
  if (filtrosQuery.buscar) {
    const semanticResults = await nlpClient.buscarEventosSemanticos(filtrosQuery.buscar, limit);
    if (semanticResults && semanticResults.length > 0) {
      // Filtrar por los IDs devueltos por la IA
      const ids = semanticResults.map(r => r.id_evento);
      filtros.id_conferencia = { in: ids };
    } else {
      // Búsqueda sin resultados semánticos (o NLP caído), fallback a búsqueda básica
      filtros.titulo = { contains: filtrosQuery.buscar, mode: 'insensitive' };
    }
  }

  const { totalRegistros, eventos } = await catalogoCtrl.findEventosPaginados(skip, take, filtros);
  const meta = buildMeta(totalRegistros, page, limit);

  return { meta, datos: eventos };
};

module.exports = {
  getEspacios,
  getEventos
};
