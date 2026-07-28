require('dotenv').config();
const express = require('express');
const cors = require('cors');
const os = require('os');
const prisma = require('./prismaClient');

// ── Rutas ──────────────────────────────────────────────────────────────────
const authRoutes = require('./routes/auth.routes');
const usuariosRoutes = require('./routes/usuarios.routes');
const edificiosRoutes = require('./routes/edificios.routes');
const aulasRoutes = require('./routes/aulas.routes');
const mobiliarioRoutes = require('./routes/mobiliario.routes');
const solicitudesRoutes = require('./routes/solicitudes.routes');
const solicitudesInmobiliarioRoutes = require('./routes/solicitudesInmobiliario.routes');
const reportesRoutes = require('./routes/reportes.routes');
const periodosRoutes = require('./routes/periodos.routes');
const actividadesRoutes = require('./routes/actividades.routes');

const ponenteRoutes = require('./routes/ponente.routes');
const misEspaciosRoutes = require('./routes/misEspacios.routes');
const eventosRoutes = require('./routes/eventos.routes');
const catalogoRoutes = require('./routes/catalogo.routes');
const incidenciasRoutes = require('./routes/incidencias.routes');
const incidenciasCrudRoutes = require('./routes/incidencias_crud.routes');

const app = express();
const PORT = process.env.PORT || 3000;

// ── Middlewares globales ────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Servir todos los uploads de manera estática
const path = require('path');
const UPLOAD_DIR = process.env.UPLOAD_DIR || 'uploads/materiales';
app.use('/uploads/materiales', express.static(path.resolve(process.cwd(), UPLOAD_DIR)));
app.use('/uploads/eventos', express.static(path.resolve(process.cwd(), 'uploads/eventos')));

// ── Montaje de rutas ────────────────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/usuarios', usuariosRoutes);
app.use('/api/edificios', edificiosRoutes);
app.use('/api/aulas', aulasRoutes);
app.use('/api/mobiliario', mobiliarioRoutes);
app.use('/api/solicitudes', solicitudesRoutes);
app.use('/api/solicitudes-inmobiliario', solicitudesInmobiliarioRoutes);
app.use('/api/reportes', reportesRoutes);
app.use('/api/periodos', periodosRoutes);
app.use('/api/actividades', actividadesRoutes);

app.use('/api/ponente', ponenteRoutes);
app.use('/api/mis-espacios', misEspaciosRoutes);
app.use('/api/eventos', eventosRoutes);
app.use('/api/catalogo', catalogoRoutes);
app.use('/api/nlp', incidenciasRoutes);
app.use('/api/incidencias', incidenciasCrudRoutes);

// ── Ruta de health check ────────────────────────────────────────────────────
app.get('/api/health', async (req, res) => {
  const nlpClient = require('./services/nlp.client');

  const healthCheck = {
    status: 'OK',
    message: 'Servidor corriendo correctamente.',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    system: {
      memory: {
        total_mb: (os.totalmem() / 1024 / 1024).toFixed(2),
        free_mb: (os.freemem() / 1024 / 1024).toFixed(2),
        usage_percent: (((os.totalmem() - os.freemem()) / os.totalmem()) * 100).toFixed(2) + '%'
      },
      cpu_load: os.loadavg()
    },
    database: 'Desconectada',
    nlp_service: 'Desconectado'
  };

  try {
    await prisma.$queryRaw`SELECT 1`;
    healthCheck.database = 'Conectada';
  } catch (error) {
    console.error('Error en health check DB:', error);
    healthCheck.status = 'DEGRADED';
    healthCheck.database = 'Error de conexión';
  }

  try {
    const nlpOk = await nlpClient.healthCheck();
    healthCheck.nlp_service = nlpOk ? 'Conectado' : 'No disponible';
  } catch {
    healthCheck.nlp_service = 'No disponible';
  }

  const httpStatus = healthCheck.database === 'Conectada' ? 200 : 503;
  return res.status(httpStatus).json(healthCheck);
});

// ── Ruta 404 ────────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ message: `Ruta ${req.originalUrl} no encontrada.` });
});

// ── Arranque ─────────────────────────────────────────────────────────────────
const server = app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
  console.log(`📡 Health check: http://localhost:${PORT}/api/health`);
});

// Aumentar el timeout de la conexión HTTP a 6 minutos para soportar
// el procesamiento en lotes del endpoint /api/reportes/clustering
// (100 reportes × 4 lotes de 25 ≈ ~4 minutos en t3.small)
server.keepAliveTimeout = 360000; // 6 min
server.headersTimeout   = 365000; // Siempre > keepAliveTimeout
