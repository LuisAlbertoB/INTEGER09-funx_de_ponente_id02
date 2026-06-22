const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Obtener la ruta base desde variables de entorno o usar valor por defecto
const UPLOAD_DIR = process.env.UPLOAD_DIR || 'uploads/materiales';
const absoluteUploadDir = path.resolve(process.cwd(), UPLOAD_DIR);

// Asegurarse de que el directorio exista
if (!fs.existsSync(absoluteUploadDir)) {
  fs.mkdirSync(absoluteUploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    // Si en el futuro se migra a S3, la abstracción se puede hacer a nivel de controlador o aquí mismo 
    // reemplazando `multer.diskStorage` por `multer-s3`.
    cb(null, absoluteUploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, file.fieldname + '-' + uniqueSuffix + ext);
  }
});

// Filtro simple para evitar ejecutables o scripts
const fileFilter = (req, file, cb) => {
  const allowedExtensions = ['.pdf', '.pptx', '.ppt', '.doc', '.docx', '.jpg', '.jpeg', '.png', '.mp4', '.zip'];
  const ext = path.extname(file.originalname).toLowerCase();
  if (allowedExtensions.includes(ext)) {
    cb(null, true);
  } else {
    cb(new Error(`Tipo de archivo no permitido. Extensiones válidas: ${allowedExtensions.join(', ')}`), false);
  }
};

const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 50 * 1024 * 1024 // Limite de 50MB por archivo
  },
  fileFilter: fileFilter
});

module.exports = upload;
