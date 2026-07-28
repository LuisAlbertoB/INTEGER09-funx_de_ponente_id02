const prisma = require('../prismaClient');

// ─── Mapeo DTO → Flutter ──────────────────────────────────────────────────────

function toDto(inc) {
  return {
    id: `INC-${String(inc.id_incidencia).padStart(3, '0')}`,
    dbId: inc.id_incidencia,
    description: inc.descripcion,
    category: inc.categoria,
    priority: inc.prioridad,
    status: inc.estado,
    location: inc.ubicacion,
    assignedTo: inc.asignado_a ?? null,
    affectedCount: inc.afectados,
    groupedReports: Array.isArray(inc.reportes_agrupados)
      ? inc.reportes_agrupados
      : [inc.descripcion],
    eventId: inc.id_conferencia ? String(inc.id_conferencia) : null,
    eventName: inc.nombre_evento,
    reportedBy: inc.reportado_por,
    createdAt: inc.createdAt.toISOString(),
    resolvedAt: inc.resuelto_at ? inc.resuelto_at.toISOString() : null,
  };
}

// ─── CRUD ─────────────────────────────────────────────────────────────────────

async function listar({ conferencia_id, estado } = {}) {
  const where = {};
  if (conferencia_id) where.id_conferencia = parseInt(conferencia_id);
  if (estado) where.estado = estado;

  const items = await prisma.incidencia.findMany({
    where,
    orderBy: [{ prioridad: 'asc' }, { createdAt: 'desc' }],
  });
  return items.map(toDto);
}

async function crear(data) {
  const inc = await prisma.incidencia.create({
    data: {
      descripcion: data.descripcion,
      categoria: data.categoria ?? 'other',
      prioridad: data.prioridad ?? 'low',
      estado: 'open',
      ubicacion: data.ubicacion || 'Sin especificar',
      nombre_evento: data.nombre_evento || 'Evento general',
      reportado_por: data.reportado_por || 'Usuario',
      reportes_agrupados: Array.isArray(data.reportes_agrupados)
        ? data.reportes_agrupados
        : [data.descripcion],
      ...(data.id_conferencia && { id_conferencia: parseInt(data.id_conferencia) }),
      ...(data.id_usuario && { id_usuario_reportante: parseInt(data.id_usuario) }),
    },
  });
  return toDto(inc);
}

async function actualizarEstado(dbId, estado) {
  const data = { estado };
  if (estado === 'resolved') data.resuelto_at = new Date();
  const inc = await prisma.incidencia.update({
    where: { id_incidencia: parseInt(dbId) },
    data,
  });
  return toDto(inc);
}

async function unirse(dbId) {
  const inc = await prisma.incidencia.update({
    where: { id_incidencia: parseInt(dbId) },
    data: { afectados: { increment: 1 } },
  });
  return toDto(inc);
}

module.exports = { listar, crear, actualizarEstado, unirse };
