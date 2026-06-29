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

const app = express();
const PORT = process.env.PORT || 3000;

// ── Middlewares globales ────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Servir la carpeta de uploads de manera estática
const path = require('path');
const UPLOAD_DIR = process.env.UPLOAD_DIR || 'uploads/materiales';
app.use('/uploads/materiales', express.static(path.resolve(process.cwd(), UPLOAD_DIR)));

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

// ── Ruta de health check ────────────────────────────────────────────────────
app.get('/api/health', async (req, res) => {
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
    database: 'Desconectada'
  };

  try {
    await prisma.$queryRaw`SELECT 1`;
    healthCheck.database = 'Conectada';
    return res.status(200).json(healthCheck);
  } catch (error) {
    console.error('Error en health check:', error);
    healthCheck.status = 'ERROR';
    healthCheck.message = 'Error conectando a la base de datos.';
    healthCheck.database = 'Error de conexión';
    healthCheck.error_details = error.message;
    return res.status(503).json(healthCheck);
  }
});

// ── Ruta 404 ────────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ message: `Ruta ${req.originalUrl} no encontrada.` });
});

// ── Arranque ─────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
  console.log(`📡 Health check: http://localhost:${PORT}/api/health`);
});
