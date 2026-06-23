FROM node:18-bullseye-slim

# Instalar dependencias del sistema necesarias para Prisma
RUN apt-get update -y && apt-get install -y openssl

# Crear directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./
COPY prisma ./prisma/

# Instalar dependencias de Node
RUN npm install

# Generar Prisma Client
RUN npx prisma generate

# Copiar el resto del código de la aplicación
COPY . .

# Exponer el puerto de la aplicación
EXPOSE 3000

# Comando para iniciar la aplicación, asegurando que la BD esté lista
CMD ["npm", "start"]
