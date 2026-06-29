const prisma = require('../prismaClient');
const bcrypt = require('bcryptjs');

const findByMatricula = async (matricula) => {
  return prisma.usuario.findUnique({ where: { matricula } });
};

const findById = async (id) => {
  return prisma.usuario.findUnique({ where: { id_usuario: id } });
};

const findAll = async (skip, take) => {
  return Promise.all([
    prisma.usuario.findMany({
      skip,
      take,
      select: {
        id_usuario: true,
        nombre_completo: true,
        matricula: true,
        rol: true,
        estado: true,
        createdAt: true,
        updatedAt: true,
        creador: {
          select: { id_usuario: true, nombre_completo: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    }),
    prisma.usuario.count()
  ]);
};

const create = async ({ nombre_completo, matricula, contrasena, rol, id_user_creator }) => {
  const hashedPassword = await bcrypt.hash(contrasena, 10);
  return prisma.usuario.create({
    data: {
      nombre_completo,
      matricula,
      contrasena: hashedPassword,
      rol,
      estado: 1,
      id_user_creator,
    },
    select: {
      id_usuario: true,
      nombre_completo: true,
      matricula: true,
      rol: true,
      estado: true,
      createdAt: true,
    },
  });
};

const updateEstado = async (id, estado) => {
  return prisma.usuario.update({
    where: { id_usuario: id },
    data: { estado },
    select: {
      id_usuario: true,
      nombre_completo: true,
      matricula: true,
      estado: true
    }
  });
};

const remove = async (id) => {
  return prisma.usuario.delete({ where: { id_usuario: id } });
};

const comparePassword = async (plain, hashed) => {
  return bcrypt.compare(plain, hashed);
};

module.exports = { findByMatricula, findById, findAll, create, updateEstado, remove, comparePassword };
