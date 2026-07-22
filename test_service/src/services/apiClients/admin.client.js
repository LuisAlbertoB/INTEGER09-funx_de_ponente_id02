const apiClient = require('./base.client');

// ── Usuarios ──────────────────────────────────────────────────────────────
const getUsuarios = async () => (await apiClient.get('/api/usuarios')).data;
const createUsuario = async (data) => (await apiClient.post('/api/usuarios', data)).data;
const updateEstadoUsuario = async (id, estado) => (await apiClient.put(`/api/usuarios/${id}/estado`, { estado })).data;

// ── Edificios ─────────────────────────────────────────────────────────────
const getEdificios = async () => (await apiClient.get('/api/edificios')).data;
const getEdificioById = async (id) => (await apiClient.get(`/api/edificios/${id}`)).data;
const createEdificio = async (data) => (await apiClient.post('/api/edificios', data)).data;
const updateEdificio = async (id, data) => (await apiClient.put(`/api/edificios/${id}`, data)).data;

// ── Aulas ─────────────────────────────────────────────────────────────────
const getAulas = async () => (await apiClient.get('/api/aulas')).data;
const getAulaById = async (id) => (await apiClient.get(`/api/aulas/${id}`)).data;
const createAula = async (data) => (await apiClient.post('/api/aulas', data)).data;
const updateAula = async (id, data) => (await apiClient.put(`/api/aulas/${id}`, data)).data;

// ── Actividades ───────────────────────────────────────────────────────────
const getActividades = async () => (await apiClient.get('/api/actividades')).data;
const getActividadById = async (id) => (await apiClient.get(`/api/actividades/${id}`)).data;
const createActividad = async (data) => (await apiClient.post('/api/actividades', data)).data;
const updateActividad = async (id, data) => (await apiClient.put(`/api/actividades/${id}`, data)).data;

// ── Mobiliario ────────────────────────────────────────────────────────────
const getMobiliario = async () => (await apiClient.get('/api/mobiliario')).data;
const getMobiliarioById = async (id) => (await apiClient.get(`/api/mobiliario/${id}`)).data;
const createMobiliario = async (data) => (await apiClient.post('/api/mobiliario', data)).data;
const updateMobiliario = async (id, data) => (await apiClient.put(`/api/mobiliario/${id}`, data)).data;

// ── Periodos ──────────────────────────────────────────────────────────────
const getPeriodos = async () => (await apiClient.get('/api/periodos')).data;
const getPeriodoActivo = async () => (await apiClient.get('/api/periodos/active')).data;
const updatePeriodo = async (id, data) => (await apiClient.put(`/api/periodos/${id}`, data)).data;

module.exports = {
  getUsuarios, createUsuario, updateEstadoUsuario,
  getEdificios, getEdificioById, createEdificio, updateEdificio,
  getAulas, getAulaById, createAula, updateAula,
  getActividades, getActividadById, createActividad, updateActividad,
  getMobiliario, getMobiliarioById, createMobiliario, updateMobiliario,
  getPeriodos, getPeriodoActivo, updatePeriodo
};
