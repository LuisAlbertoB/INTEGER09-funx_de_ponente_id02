# 🚀 Backend Core API (Node.js + Express + Prisma)

Este módulo es el corazón del Marketplace Académico. Actúa como el orquestador principal, manejando la lógica de negocio, la seguridad (JWT), la persistencia de datos (PostgreSQL vía Prisma) y la comunicación con el microservicio de Inteligencia Artificial (FastAPI).

## 🛠️ Tecnologías Principales
- **Entorno:** Node.js
- **Framework Web:** Express.js
- **ORM:** Prisma
- **Base de Datos:** PostgreSQL
- **Seguridad:** JSON Web Tokens (JWT) & bcrypt
- **Integración IA:** Axios (Cliente HTTP interno hacia el contenedor NLP)

---

## 🏗️ Infraestructura y Despliegue (AWS EC2)

El proyecto está diseñado para ser desplegado mediante contenedores en una instancia de AWS EC2 (t3.medium). Toda la orquestación está manejada por `docker-compose.yml`.

```mermaid
graph TD
    Client[📱 Flutter App] -->|HTTP / Puerto 80| API(🟢 Node.js API Container)
    
    subgraph EC2 Instance [☁️ AWS EC2 t3.medium]
        API <-->|Red Interna| NLP(🐍 FastAPI NLP Container)
        API <-->|Red Interna| DB[(🐘 PostgreSQL 15)]
    end
    
    NLP -->|Read/Write| FAISS[(🧠 Modelos y Vectores FAISS)]
    DB -->|Volumen Persistente| PGData[(💾 pgdata Volume)]
```
*Nota de Seguridad:* El contenedor de Inteligencia Artificial (FastAPI) y la Base de Datos operan en una red privada de Docker. No exponen puertos al exterior; el único punto de entrada a la nube es a través de la API de Node.js.

---

## 🗄️ Construcción de la Base de Datos

La base de datos relacional (PostgreSQL) está modelada utilizando **Prisma ORM**. Abajo se ilustra la arquitectura de las entidades principales:

```mermaid
erDiagram
    Usuario ||--o{ Conferencia : "Crea (Ponente)"
    Usuario ||--o{ EvaluacionEvento : "Califica (Alumno)"
    Usuario ||--o{ Reporte : "Levanta"
    Conferencia ||--o{ EvaluacionEvento : "Recibe"
    Conferencia ||--o{ Solicitud : "Requiere (Aula/Espacio)"
    PeriodoAcademico ||--o{ Conferencia : "Contiene"

    Usuario {
        int id_usuario PK
        string matricula
        string rol "admin | ponente | participante"
    }
    Conferencia {
        int id_conferencia PK
        string titulo
        string descripcion
        int id_ponente FK
    }
    EvaluacionEvento {
        int id_evaluacion PK
        int calificacion "1 a 5"
        string comentario_escrito
        int id_usuario FK
        int id_evento FK
    }
    Reporte {
        int id_reporte PK
        string titulo
        string descripcion
        int id_aula FK
    }
```

---

## 🔌 API Endpoints y Cómo Utilizarlos

Todas las rutas (excepto login) requieren un token JWT válido que debe enviarse en las cabeceras de la petición: `Authorization: Bearer <TU_TOKEN>`.

### 🔐 Autenticación
- **`POST /api/auth/login`**: Iniciar sesión.
  - *Body:* `{ "matricula": "000000", "contrasena": "admin1" }`
  - *Devuelve:* Token JWT y datos del usuario.

### 📅 Eventos y Catálogo
- **`GET /api/catalogo/eventos?buscar=texto`**: Búsqueda Inteligente (Semántica). Devuelve eventos cuyo significado vectorial coincida con el texto.
- **`GET /api/eventos/recomendados`**: Obtiene recomendaciones personalizadas basadas en el historial del usuario actual usando Collaborative Filtering.
- **`POST /api/eventos`**: Crear un evento. (Internamente dispara el NLP para vectorizar la descripción).

### ⭐ Evaluaciones
- **`POST /api/eventos/:id/evaluacion`**: Evaluar un evento.
  - *Body:* `{ "calificacion": 5, "porcentaje_satisfaccion": 100, "comentario_escrito": "Excelente curso" }`
  - *Dato Técnico:* Esto nutre la red de recomendaciones y analiza el sentimiento del texto (positivo/negativo).

### 🛠️ Reportes de Mantenimiento
- **`POST /api/reportes`**: Levantar un ticket sobre un equipo roto. Extrae entidades automáticamente (NER).
- **`GET /api/reportes/clustering`**: Endpoint de Administrador. Devuelve todos los reportes agrupados matemáticamente por similitud temática sin etiquetado manual previo.

---

## ⚙️ Requisitos Previos e Instalación Local (Desarrollo)

1. **Instalar dependencias:** `npm install`
2. **Variables de Entorno (`.env`):**
   ```env
   DATABASE_URL="postgresql://usuario:password@localhost:5432/db?schema=public"
   NLP_SERVICE_URL="http://localhost:8000"
   JWT_SECRET="tu_secreto_super_seguro"
   PORT=3000
   ```
3. **Migraciones:** `npx prisma db push`
4. **Ejecutar:** `npm run dev`

---

## 🧠 Integración con Inteligencia Artificial (Diseño "Fire & Forget")
Este backend **no procesa** modelos de Machine Learning pesados para evitar bloquear el hilo principal de Node.js (Event Loop). Delega el trabajo al contenedor NLP.
Cuando se requiere guardar datos que alimentan a la IA (como crear un evento), Node.js responde al cliente de inmediato (201 Created) y procesa el vector matemático asíncronamente en segundo plano.
