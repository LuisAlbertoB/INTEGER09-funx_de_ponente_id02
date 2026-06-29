require('dotenv').config();
const express = require('express');
const cors = require('cors');

const testRoutes = require('./routes/test.routes');

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/api/test', testRoutes);

// Health check para la propia Test Machine
app.get('/api/health', (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    message: 'Test Machine Operativa',
    target: process.env.TARGET_API_URL 
  });
});

app.listen(PORT, () => {
  console.log(`🤖 Test Machine corriendo en http://localhost:${PORT}`);
  console.log(`🎯 Apuntando a API Principal en: ${process.env.TARGET_API_URL}`);
});
