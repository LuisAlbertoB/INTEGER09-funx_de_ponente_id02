const apiClient = require('./base.client');

const createEvento = async (data) => {
  const response = await apiClient.post('/api/eventos', data);
  return response.data;
};

const solicitarEspacio = async (idEvento, idEspacio, data) => {
  const response = await apiClient.post(`/api/eventos/${idEvento}/solicitar-espacio/${idEspacio}`, data);
  return response.data;
};

const submitEvaluacion = async (idEvento, data) => {
  const response = await apiClient.post(`/api/eventos/${idEvento}/evaluacion`, data);
  return response.data;
};

module.exports = { createEvento, solicitarEspacio, submitEvaluacion };
