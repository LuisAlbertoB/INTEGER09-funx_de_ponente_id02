require('dotenv').config();
const axios = require('axios');
const StateStore = require('../../store/StateStore');

const targetUrl = process.env.TARGET_API_URL || 'http://localhost:3000';

const apiClient = axios.create({
  baseURL: targetUrl,
  timeout: 10000,
});

// Interceptor para inyectar token automáticamente
apiClient.interceptors.request.use((config) => {
  // Por defecto, usa el token del usuario actual si existe en el estado
  const token = StateStore.get('active_token');
  if (token) {
    config.headers['Authorization'] = `Bearer ${token}`;
  }
  return config;
}, (error) => {
  return Promise.reject(error);
});

module.exports = apiClient;
