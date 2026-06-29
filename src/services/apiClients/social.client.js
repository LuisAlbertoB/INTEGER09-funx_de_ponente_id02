const apiClient = require('./base.client');

const getForo = async (idEvento) =>
  (await apiClient.get(`/api/eventos/${idEvento}/foro`)).data;

const postComentario = async (idEvento, data) =>
  (await apiClient.post(`/api/eventos/${idEvento}/foro`, data)).data;

module.exports = { getForo, postComentario };
