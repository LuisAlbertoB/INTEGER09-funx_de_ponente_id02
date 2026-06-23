/**
 * Middleware: verifyOwner
 * Verifica que el recurso solicitado pertenece al usuario autenticado.
 * Admin siempre tiene acceso, sin importar la propiedad.
 *
 * Uso: Se aplica DESPUÉS de verifyToken, en rutas donde el controlador
 * necesita saber si el usuario es dueño del recurso.
 *
 * Agrega req.isOwner = true/false para que el controlador decida qué hacer.
 * El ID del propietario debe estar disponible en req.resourceOwnerId (seteado por el controlador).
 *
 * IMPORTANTE: Este middleware NO bloquea por sí solo; deja la decisión final
 * al controlador, que puede combinar req.isOwner con req.user.rol para
 * lógica más granular (ej: ponente puede ver lo suyo, coordinador puede ver más).
 */
const verifyOwner = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ message: 'No autenticado.' });
  }

  // Admin siempre es considerado propietario de todo
  if (req.user.rol === 'admin') {
    req.isOwner = true;
    return next();
  }

  // req.resourceOwnerId debe ser seteado previamente por el controlador
  // Si no está seteado aún, lo resolvemos en el controlador
  req.isOwner = req.resourceOwnerId
    ? req.resourceOwnerId === req.user.id_usuario
    : false;

  next();
};

module.exports = verifyOwner;
