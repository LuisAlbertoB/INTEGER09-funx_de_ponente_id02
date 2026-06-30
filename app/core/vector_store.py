"""
Motor de Búsqueda Vectorial usando FAISS.
Maneja la persistencia de los embeddings en disco para no perderlos al reiniciar.
"""

import os
import json
import faiss
import numpy as np

# Rutas de almacenamiento
INDEX_FILE = "models_cache/eventos.faiss"
MAPPING_FILE = "models_cache/eventos_mapping.json"

# Dimensión de los embeddings de hiiamsid/sentence_similarity_spanish_es
EMBEDDING_DIM = 768 

class VectorStore:
    def __init__(self):
        # Asegurar que el directorio exista
        os.makedirs("models_cache", exist_ok=True)
        
        self.index = None
        # Mapeo de índice interno de FAISS (int) a ID real del Evento (int)
        self.id_mapping = {}
        
        self.load()

    def load(self):
        """Carga el índice FAISS y el mapeo desde el disco si existen."""
        if os.path.exists(INDEX_FILE) and os.path.exists(MAPPING_FILE):
            print(f"📂 Cargando base de datos vectorial desde {INDEX_FILE}...")
            self.index = faiss.read_index(INDEX_FILE)
            with open(MAPPING_FILE, "r") as f:
                # json guarda keys como string, las pasamos a int
                mapping_str = json.load(f)
                self.id_mapping = {int(k): int(v) for k, v in mapping_str.items()}
            print(f"   ✅ Vectores cargados: {self.index.ntotal}")
        else:
            print("📂 Creando nueva base de datos vectorial (FAISS)...")
            # IndexFlatL2 usa distancia Euclidiana (L2). Para similitud Coseno, 
            # normalizamos los vectores antes de insertarlos.
            self.index = faiss.IndexFlatL2(EMBEDDING_DIM)
            self.id_mapping = {}

    def save(self):
        """Guarda el índice FAISS y el mapeo en el disco."""
        faiss.write_index(self.index, INDEX_FILE)
        with open(MAPPING_FILE, "w") as f:
            json.dump(self.id_mapping, f)

    def add_event(self, event_id: int, embedding: np.ndarray):
        """Añade o actualiza el embedding de un evento."""
        # Normalizar el vector para que L2 actúe como similitud Coseno
        faiss.normalize_L2(embedding)
        
        # En FAISS IndexFlatL2 no podemos borrar vectores fácilmente.
        # Si el evento ya existe, lo ideal sería reconstruir el índice o usar un IndexIDMap.
        # Para simplificar en este MVP, si ya existe no lo volvemos a meter,
        # o lo agregamos y simplemente en la búsqueda priorizamos el más reciente.
        # Mejor aún, veamos si ya lo tenemos mapeado:
        if event_id in self.id_mapping.values():
            # Ya existe, ignoramos (para actualizar habría que usar IndexIDMap)
            return False

        # Agregar al índice
        current_faiss_id = self.index.ntotal
        self.index.add(embedding)
        self.id_mapping[current_faiss_id] = event_id
        
        self.save()
        return True

    def search(self, query_embedding: np.ndarray, top_k: int = 5):
        """Busca los top_k eventos más similares."""
        if self.index.ntotal == 0:
            return []

        # Normalizar la consulta
        faiss.normalize_L2(query_embedding)
        
        # Buscar
        distances, indices = self.index.search(query_embedding, top_k)
        
        results = []
        for i, faiss_id in enumerate(indices[0]):
            if faiss_id != -1 and faiss_id in self.id_mapping:
                # Distancia L2 normalizada: menor es mejor (0 es idéntico)
                # Convertimos a un 'score' intuitivo (1.0 es perfecto)
                score = 1.0 - (distances[0][i] / 2.0)  
                results.append({
                    "id_evento": self.id_mapping[faiss_id],
                    "score": round(float(score), 4)
                })
                
        return results

# Singleton
vector_store = VectorStore()
