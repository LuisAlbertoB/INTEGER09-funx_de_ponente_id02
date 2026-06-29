const apiClient = require('./base.client');

const createEspacio = async (data) => {
  const response = await apiClient.post('/api/mis-espacios', data);
  return response.data;
};

const getSolicitudes = async () => {
  const response = await apiClient.get('/api/mis-espacios/solicitudes');
  return response.data;
};

const aprobarSolicitud = async (idSolicitud) => {
  const response = await apiClient.put(`/api/mis-espacios/solicitudes/${idSolicitud}/aprobar`);
  return response.data;
};

module.exports = { createEspacio, getSolicitudes, aprobarSolicitud };
