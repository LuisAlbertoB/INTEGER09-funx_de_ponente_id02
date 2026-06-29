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

  // Construir filtros simples si es necesario
  const filtros = {};
  if (filtrosQuery.tematica) {
    filtros.tematica = { contains: filtrosQuery.tematica, mode: 'insensitive' };
  }

  const { totalRegistros, eventos } = await catalogoCtrl.findEventosPaginados(skip, take, filtros);
  const meta = buildMeta(totalRegistros, page, limit);

  return { meta, datos: eventos };
};

module.exports = {
  getEspacios,
  getEventos
};
