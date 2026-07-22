#!/usr/bin/env bash

echo "========================================================"
echo "🚀 Reparando y Publicando Archivos Completos en 'main'"
echo "========================================================"

# Verificar si git está instalado
if ! command -v git &> /dev/null; then
    echo "❌ Error: git no está instalado. Por favor instala git en tu sistema."
    exit 1
fi

# Eliminar cualquier carpeta .git anidada para evitar submódulos
echo "🧹 Eliminando carpetas .git anidadas en los subdirectorios..."
find . -mindepth 2 -name ".git" -exec rm -rf {} + 2>/dev/null || true

# Inicializar o preparar el repositorio en la raíz
if [ ! -d ".git" ]; then
    git init
    git remote add origin https://github.com/LuisAlbertoB/INTEGER09-funx_de_ponente_id02.git
fi

# Cambiar a la rama main
git checkout main 2>/dev/null || git checkout -b main

# Limpiar la memoria caché de Git para eliminar referencias de submódulos (gitlinks)
echo "🔄 Limpiando índice de submódulos en Git..."
git rm -r --cached . 2>/dev/null || true

# Agregar todos los archivos reales de cada subdirectorio
echo "📦 Agregando todos los archivos físicos al control de versiones..."
git add .

# Hacer commit
git commit -m "fix: incluir archivos físicos reales de cada microservicio en la rama main"

# Publicar la rama main en GitHub forzando actualización de la estructura
echo "⬆️ Enviando todos los archivos físicos a GitHub..."
git push -u origin main --force

echo "========================================================"
echo "✅ ¡Subdirectorios y archivos físicos publicados correctamente en GitHub!"
echo "========================================================"
