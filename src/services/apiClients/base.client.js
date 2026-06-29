require('dotenv').config();
const axios = require('axios');
const StateStore = require('../../store/StateStore');

const targetUrl = process.env.TARGET_API_URL || 'http://localhost:3000';

const apiClient = axios.create({
  baseURL: targetUrl,
  timeout: 10000,
});

apiClient.interceptors.request.use((config) => {
  const token = StateStore.get('active_token');
  if (token) {
    config.headers['Authorization'] = `Bearer ${token}`;
  }
  return config;
});

module.exports = apiClient;
