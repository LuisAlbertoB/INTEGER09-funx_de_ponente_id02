/**
 * Middleware: verifyCoordinador
 * Permite acceso a usuarios con rol 'coordinador' o 'admin'.
 */
const verifyCoordinador = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ message: 'No autenticado.' });
  }

  if (!['coordinador', 'admin'].includes(req.user.rol)) {
    return res.status(403).json({ message: 'Acceso denegado. Se requiere rol de coordinador.' });
  }

  next();
};

module.exports = verifyCoordinador;
