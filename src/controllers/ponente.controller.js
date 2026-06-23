const prisma = require('../prismaClient');

// GET /api/ponente/conferencias
// Lista las conferencias del ponente autenticado
const getMisConferencias = async (req, res) => {
  try {
    const conferencias = await prisma.conferencia.findMany({
      where: {
        id_ponente: req.user.id_usuario,
        estado: 1 // Solo activas
      },
      include: {
        actividad: true,
        aula: { select: { nombre_clave: true, edificio: { select: { nombre_clave: true } } } },
        periodo: true,
        materiales: true,
        registroEvento: true
      },
      orderBy: { createdAt: 'desc' }
    });
    return res.status(200).json(conferencias);
  } catch (error) {
    console.error('Error en getMisConferencias:', error);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
};

// POST /api/ponente/conferencias
// Crea una nueva conferencia
const createConferencia = async (req, res) => {
  const { titulo, descripcion, tematica, nivel_academico_objetivo, duracion_estimada_min, id_actividad, id_periodo, id_aula_utilizada } = req.body;

  if (!titulo || !id_actividad || !id_periodo) {
    return res.status(400).json({ message: 'Faltan campos obligatorios: titulo, id_actividad, id_periodo.' });
  }

  try {
    const nuevaConferencia = await prisma.conferencia.create({
      data: {
        titulo,
        descripcion,
        tematica,
        nivel_academico_objetivo,
        duracion_estimada_min: duracion_estimada_min ? Number(duracion_estimada_min) : undefined,
        id_ponente: req.user.id_usuario,
        id_actividad: Number(id_actividad),
        id_periodo: Number(id_periodo),
        id_aula_utilizada: id_aula_utilizada ? Number(id_aula_utilizada) : null,
      }
    });

    return res.status(201).json({ message: 'Conferencia creada.', conferencia: nuevaConferencia });
  } catch (error) {
    console.error('Error en createConferencia:', error);
    return res.status(500).json({ message: 'Error al crear la conferencia.' });
  }
};

// PUT /api/ponente/conferencias/:id
// Actualiza una conferencia
const updateConferencia = async (req, res) => {
  const { id } = req.params;
  const data = req.body;

  try {
    const conferenciaId = Number(id);
    
    // El middleware verifyOwner ya validó que esta conferencia le pertenece al usuario actual
    if (!req.isOwner && req.user.rol !== 'admin') {
      return res.status(403).json({ message: 'No tienes permiso para modificar esta conferencia.' });
    }

    const actualizada = await prisma.conferencia.update({
      where: { id_conferencia: conferenciaId },
      data: {
        titulo: data.titulo,
        descripcion: data.descripcion,
        tematica: data.tematica,
        nivel_academico_objetivo: data.nivel_academico_objetivo,
        duracion_estimada_min: data.duracion_estimada_min ? Number(data.duracion_estimada_min) : undefined,
        id_aula_utilizada: data.id_aula_utilizada ? Number(data.id_aula_utilizada) : undefined,
      }
    });

    return res.status(200).json({ message: 'Conferencia actualizada.', conferencia: actualizada });
  } catch (error) {
    console.error('Error en updateConferencia:', error);
    return res.status(500).json({ message: 'Error al actualizar la conferencia.' });
  }
};

// DELETE /api/ponente/conferencias/:id
// Soft delete de una conferencia
const deleteConferencia = async (req, res) => {
  const { id } = req.params;

  try {
    const conferenciaId = Number(id);

    if (!req.isOwner && req.user.rol !== 'admin') {
      return res.status(403).json({ message: 'No tienes permiso para eliminar esta conferencia.' });
    }

    await prisma.conferencia.update({
      where: { id_conferencia: conferenciaId },
      data: { estado: 0 } // baja lógica
    });

    return res.status(200).json({ message: 'Conferencia eliminada correctamente.' });
  } catch (error) {
    console.error('Error en deleteConferencia:', error);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
};

// POST /api/ponente/conferencias/:id/materiales
// Sube un archivo y crea el registro de MaterialDeApoyo
const uploadMaterial = async (req, res) => {
  const { id } = req.params;
  const { titulo_material, tipo_archivo, publico } = req.body;
  const file = req.file;

  if (!file) {
    return res.status(400).json({ message: 'No se subió ningún archivo.' });
  }
  
  if (!titulo_material) {
    // Si la subida falla, habría que borrar el archivo temporal pero Multer lo guarda antes de que lleguemos aquí.
    // Un flujo más robusto limpiaría el archivo en catch.
    return res.status(400).json({ message: 'titulo_material es requerido.' });
  }

  try {
    const conferenciaId = Number(id);

    if (!req.isOwner && req.user.rol !== 'admin') {
      return res.status(403).json({ message: 'No tienes permiso para agregar material a esta conferencia.' });
    }

    // El archivo se guardó localmente según la configuración de Multer
    const url_almacenamiento = `/uploads/materiales/${file.filename}`;

    const material = await prisma.materialDeApoyo.create({
      data: {
        titulo_material,
        tipo_archivo: tipo_archivo || 'otro',
        url_almacenamiento,
        tamanio_bytes: file.size,
        publico: publico === 'false' ? false : true,
        id_conferencia: conferenciaId
      }
    });

    return res.status(201).json({ message: 'Material subido exitosamente.', material });
  } catch (error) {
    console.error('Error en uploadMaterial:', error);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
};

// Función auxiliar middleware para inyectar `resourceOwnerId` antes de `verifyOwner`
const injectConferenciaOwner = async (req, res, next) => {
  const { id } = req.params;
  try {
    const conferencia = await prisma.conferencia.findUnique({
      where: { id_conferencia: Number(id) },
      select: { id_ponente: true }
    });
    if (!conferencia) {
      return res.status(404).json({ message: 'Conferencia no encontrada.' });
    }
    req.resourceOwnerId = conferencia.id_ponente;
    next();
  } catch (error) {
    return res.status(500).json({ message: 'Error interno.' });
  }
};

module.exports = {
  getMisConferencias,
  createConferencia,
  updateConferencia,
  deleteConferencia,
  uploadMaterial,
  injectConferenciaOwner
};
