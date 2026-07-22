# 🚀 Marketplace Académico y Gestión de Campus con IA (Monorepo)

Bienvenido al repositorio central unificado (`main`) del **Marketplace Académico**. Este proyecto integra la orquestación de la plataforma, un microservicio de Inteligencia Artificial para procesamiento de lenguaje natural y minería de datos, una aplicación móvil para los usuarios del campus, generadores de datos masivos y suites de pruebas de integración.

---

## 🏗️ Arquitectura del Monorepo

El proyecto está consolidado en la rama `main` en los siguientes subdirectorios principales:

```
00Proyecto9/
├── 📁 server/          # Backend Core (Node.js + Express + Prisma + PostgreSQL)
├── 📁 nlp_service/      # Microservicio de IA (Python + FastAPI + Sentence-Transformers + FAISS)
├── 📁 client/           # Aplicación Móvil para Alumnos, Ponentes y Admins (Flutter)
├── 📁 data_generator/   # Scripts de generación de datos masivos sintéticos (Seeding)
├── 📁 test_service/     # Suite de pruebas de integración E2E / AWS EC2
├── 📁 docs/             # Documentación técnica y diagramas de base de datos (Mermaid)
├── 📁 brain/            # Laboratorio de ciencia de datos, notebooks y modelos (.pt)
├── 📄 docker-compose.yml # Orquestador de contenedores para producción/desarrollo local
└── 📄 README.md         # Documentación principal del sistema
```

---

## 🛠️ Tecnologías Utilizadas

- **Backend Core:** Node.js, Express.js, Prisma ORM, PostgreSQL 15, JWT, bcrypt.
- **Inteligencia Artificial & NLP:** Python 3.12, FastAPI, Sentence-Transformers, Scikit-Learn (Agglomerative Clustering), FAISS.
- **Cliente Móvil:** Flutter (Dart), soporte iOS y Android.
- **Despliegue & Contenedores:** Docker, Docker Compose, AWS EC2.

---

## ⚡ Inicio Rápido con Docker Compose

Para ejecutar todo el ecosistema (PostgreSQL + Microservicio NLP + Backend Node.js) con un solo comando:

```bash
# 1. Clonar el repositorio y posicionarse en la rama main
git clone https://github.com/LuisAlbertoB/INTEGER09-funx_de_ponente_id02.git
cd INTEGER09-funx_de_ponente_id02
git checkout main

# 2. Iniciar todos los servicios
docker-compose up --build -d
```

### Puertos expuestos por defecto:
- **API Backend Node.js:** `http://localhost:80` (o `http://localhost:3000`)
- **API Swagger IA / NLP:** `http://localhost:8000/docs` (Accesible internamente en la red de Docker)
- **Base de Datos PostgreSQL:** `localhost:5432`

---

## 🧪 Pruebas de Integración y Poblamiento de Datos

### Generación de Datos Masivos
```bash
cd data_generator
npm install
node seed_massive.js
```

### Ejecutar Pruebas E2E
```bash
cd test_service
npm install
npm test
```

---

## 📜 Licencia y Autores

Desarrollado como proyecto para el Marketplace Académico y Gestión de Campus con Inteligencia Artificial.
