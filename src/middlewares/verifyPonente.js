/**
 * Middleware: verifyPonente
 * Permite acceso a usuarios con rol 'ponente' o 'admin'.
 */
const verifyPonente = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ message: 'No autenticado.' });
  }

  if (!['ponente', 'admin'].includes(req.user.rol)) {
    return res.status(403).json({ message: 'Acceso denegado. Se requiere rol de ponente.' });
  }

  next();
};

module.exports = verifyPonente;
