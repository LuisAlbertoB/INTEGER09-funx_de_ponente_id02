const apiClient = require('./base.client');

const getMisConferencias = async () =>
  (await apiClient.get('/api/ponente/conferencias')).data;

const createConferencia = async (data) =>
  (await apiClient.post('/api/ponente/conferencias', data)).data;

const updateConferencia = async (id, data) =>
  (await apiClient.put(`/api/ponente/conferencias/${id}`, data)).data;

module.exports = { getMisConferencias, createConferencia, updateConferencia };
