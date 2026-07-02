# 🧠 Microservicio de Inteligencia Artificial (NLP & Data Mining)

Este repositorio contiene el primer componente de Inteligencia Artificial desarrollado para el proyecto final del Marketplace Académico. Se trata de un microservicio independiente construido con **FastAPI** y **Python** que provee capacidades avanzadas de Procesamiento de Lenguaje Natural (NLP) y Machine Learning no supervisado.

---

## 🏗️ Modalidad Implementada: Modelo Local

Siguiendo la propuesta aceptada, este microservicio opera bajo la modalidad de **Modelo Local**. 
No dependemos de APIs externas comerciales (como OpenAI o Google Cloud). Todos los modelos (`sentence-transformers`, `scikit-learn` para Clustering, y modelos de NER/Sentimientos) se descargan, cargan en la Memoria RAM del servidor (AWS EC2) y ejecutan la inferencia matemáticamente a nivel local. Esto garantiza privacidad total de los datos y cero latencia de red hacia terceros.

---

## 🎯 Algoritmo Seleccionado y Valor Aportado a la App Móvil

El algoritmo de Machine Learning no supervisado núcleo de este servicio es el **Agglomerative Clustering** (Agrupamiento Jerárquico), combinado con la extracción de características (Feature Extraction) mediante **Embeddings Vectoriales** usando *Sentence Transformers*.

**Valor aportado a la Aplicación Móvil:**
En un Marketplace Académico, la infraestructura es vital. Cuando cientos de estudiantes reportan fallas (ej. "el clima no enfría", "el aire acondicionado está roto", "falla el AC"), el administrador de la aplicación móvil se enfrenta a una avalancha de datos desordenados.
Nuestro algoritmo **lee los reportes, los convierte a vectores matemáticos y los agrupa en clústeres temáticos automáticamente sin necesidad de que un humano los etiquete previamente**. Esto permite que, en la aplicación móvil de Flutter, el Administrador vea directamente los "Problemas Principales" agrupados, priorizando el mantenimiento del campus.

---

## 🧮 Fundamentos Matemáticos del Servicio

Para lograr que la Inteligencia Artificial "entienda" y agrupe los textos, el microservicio implementa una serie de transformaciones matemáticas sobre el lenguaje natural:

### 1. Vectorización (Embeddings) en $\mathbb{R}^d$
El texto libre no puede procesarse aritméticamente. Utilizando el modelo de *Sentence-Transformers*, mapeamos cada oración (ej. un reporte de mantenimiento) a un espacio vectorial denso de alta dimensionalidad (típicamente $d = 384$ o $d = 768$). 
Cada texto $T_i$ se convierte en un vector $\mathbf{v}_i \in \mathbb{R}^d$.

### 2. Similitud del Coseno (Búsqueda Vectorial)
Para buscar eventos semánticamente idénticos (incluso si no usan las mismas palabras), utilizamos la métrica de Similitud del Coseno entre el vector de búsqueda $\mathbf{A}$ y los vectores de la base de datos $\mathbf{B}$ almacenados en FAISS:
$$ \text{Similitud}(\mathbf{A}, \mathbf{B}) = \cos(\theta) = \frac{\mathbf{A} \cdot \mathbf{B}}{\|\mathbf{A}\| \|\mathbf{B}\|} = \frac{\sum_{i=1}^{n} A_i B_i}{\sqrt{\sum_{i=1}^{n} A_i^2} \sqrt{\sum_{i=1}^{n} B_i^2}} $$
Un valor cercano a `1` indica que los textos significan lo mismo.

### 3. Clustering Aglomerativo (Ward's Linkage)
Para agrupar los reportes de daño de forma no supervisada, el algoritmo inicializa cada reporte como su propio clúster y luego los fusiona iterativamente.
Utilizamos el criterio de varianza mínima de Ward. En cada paso, se unen los dos clústeres $A$ y $B$ que minimicen el incremento de la suma de errores cuadráticos (Sum of Squared Errors, SSE) tras la fusión:
$$ \Delta(A, B) = \sum_{x \in A \cup B} \|x - m_{A \cup B}\|^2 - \sum_{x \in A} \|x - m_A\|^2 - \sum_{x \in B} \|x - m_B\|^2 $$
donde $m$ es el centroide (vector promedio) del clúster. Esto garantiza agrupaciones densas y temáticamente coherentes.

---

## ⚙️ Cumplimiento de Requisitos del Microservicio

El microservicio expone una API REST completa y cumple estrictamente con los lineamientos del hito:

1. **Exponer endpoints para realizar inferencias:**
   - `POST /api/ml/clustering/reportes`: Agrupa datos usando Machine Learning no supervisado.
   - `POST /api/ml/semantico/indexar`: Genera embeddings para Búsqueda Vectorial.
2. **Validar y preprocesar los datos de entrada:**
   - Todo el preprocesamiento de limpieza de texto y tokenización ocurre en los controladores internos, y la validación de payloads (esquemas estrictos) se realiza automáticamente con `Pydantic` de FastAPI.
3. **Ejecutar un algoritmo de aprendizaje no supervisado:**
   - Uso intensivo de `AgglomerativeClustering` de la librería `scikit-learn`.
4. **Devolver los resultados en formato JSON:**
   - Todas las respuestas (clústeres, etiquetas, métricas) se estructuran rigurosamente en JSON.
5. **Almacenar las inferencias en una base de datos:**
   - Los vectores resultantes de las inferencias semánticas se persisten físicamente en un archivo/base vectorial local de **FAISS** (ubicado en `models_cache/faiss_index.bin`).
6. **Exponer un endpoint para consultar las inferencias realizadas:**
   - Mediante `POST /api/ml/semantico/buscar` y `POST /api/ml/semantico/recomendaciones`, se puede consultar el historial matemático de las inferencias previas (vectores) almacenadas en la base de datos de FAISS.
7. **Documentar la API mediante Swagger/OpenAPI:**
   - La API se auto-documenta dinámicamente. Al ejecutar el proyecto, la documentación Swagger UI interactiva está disponible en la ruta raíz o en `/docs`.

---

## 📦 Estructura de los Entregables

Con base en la rúbrica de evaluación, el material del proyecto se divide de la siguiente manera:

- **Código fuente del microservicio:** 
  Se encuentra íntegramente en este repositorio, dentro de la carpeta `app/`.
- **Diagrama de Arquitectura:** 
  Los archivos visuales de la arquitectura (pdf, png, svg) se encuentran en la carpeta `docs/architecture/` (o referenciados en los anexos del equipo).
- **Documentación de la API:** 
  Puedes explorar el Swagger en vivo corriendo el proyecto y accediendo a `http://localhost:8000/docs`. Además, los esquemas Markdown están incluidos aquí.
- **Evidencia del entrenamiento:** 
  Al ser un modelo no supervisado sobre modelos pre-entrenados de HuggingFace, la "inferencia/entrenamiento" ocurre dinámicamente con los datos inyectados. La matriz de similitud se calcula en tiempo de ejecución.
- **Colección de Pruebas (Postman/Bruno):**
  Se adjunta el archivo de colección (ej. `NLP_Collection.json`) en la raíz del repositorio para importar directamente en tu cliente REST favorito.
- **Video Demostrativo:**
  El enlace al video explicativo de 5 a 10 minutos (donde probamos el Clustering y la Búsqueda Vectorial explicando su futura integración con Flutter) se encuentra en la entrega del Campus Virtual.

---

## 🚀 Instalación y Despliegue Local

### 1. Entorno Virtual y Dependencias
```bash
python -m venv .venv
source .venv/bin/activate  # En Linux/Mac
# .venv\Scripts\activate   # En Windows

pip install -r requirements.txt
```

### 2. Ejecutar el Servidor
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Una vez en ejecución, visita **http://127.0.0.1:8000/docs** para interactuar gráficamente con el motor de Inteligencia Artificial mediante Swagger UI.
