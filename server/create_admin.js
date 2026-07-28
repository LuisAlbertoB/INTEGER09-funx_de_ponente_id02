'use strict';
require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  const matricula = 'rodrigo@gmail.com';
  const contrasena = '123123123';
  const nombre    = 'Rodrigo';
  const rol       = 'admin';

  const existing = await prisma.usuario.findUnique({ where: { matricula } });
  if (existing) {
    console.log(`✅ El usuario "${matricula}" ya existe (id: ${existing.id_usuario}).`);
    return;
  }

  const hash = await bcrypt.hash(contrasena, 10);
  const user = await prisma.usuario.create({
    data: { nombre_completo: nombre, matricula, contrasena: hash, rol, estado: 1 },
  });

  console.log(`✅ Admin creado — id: ${user.id_usuario}, matrícula: ${matricula}`);
}

main()
  .catch((e) => { console.error('❌ Error:', e.message); process.exit(1); })
  .finally(() => prisma.$disconnect());
