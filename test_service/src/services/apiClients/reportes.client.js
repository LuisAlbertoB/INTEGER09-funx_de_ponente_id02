const apiClient = require('./base.client');

const getReportes = async () => (await apiClient.get('/api/reportes')).data;
const createReporte = async (data) => (await apiClient.post('/api/reportes', data)).data;
const updateReporte = async (id, data) => (await apiClient.put(`/api/reportes/${id}`, data)).data;

module.exports = { getReportes, createReporte, updateReporte };
