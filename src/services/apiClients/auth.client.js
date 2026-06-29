const apiClient = require('./base.client');
const StateStore = require('../../store/StateStore');

const login = async (matricula, contrasena, storeKey = 'active_token') => {
  const response = await apiClient.post('/api/auth/login', { matricula, contrasena });
  if (response.data && response.data.token) {
    StateStore.set(storeKey, response.data.token);
    StateStore.set('active_token', response.data.token);
  }
  return response.data;
};

module.exports = {
  login
};
