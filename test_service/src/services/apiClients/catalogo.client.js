const apiClient = require('./base.client');

const getEspacios = async (page = 1, limit = 5) =>
  (await apiClient.get('/api/catalogo/espacios', { params: { page, limit } })).data;

const getEventos = async (page = 1, limit = 5) =>
  (await apiClient.get('/api/catalogo/eventos', { params: { page, limit } })).data;

module.exports = { getEspacios, getEventos };
