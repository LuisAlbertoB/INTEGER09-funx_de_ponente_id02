#!/usr/bin/env bash

echo "========================================================"
echo "🚀 Publicando la estructura Monorepo en la rama 'main'"
echo "========================================================"

# Verificar si git está instalado
if ! command -v git &> /dev/null; then
    echo "❌ Error: git no está instalado. Por favor instala git en tu sistema."
    exit 1
fi

# Inicializar o preparar el repositorio en la raíz
if [ ! -d ".git" ]; then
    git init
    git remote add origin https://github.com/LuisAlbertoB/INTEGER09-funx_de_ponente_id02.git
fi

# Cambiar a la rama main
git checkout -b main 2>/dev/null || git checkout main

# Agregar todos los archivos estructurados del Monorepo
git add .

# Hacer commit
git commit -m "feat: consolidación del proyecto completo en la rama main (Monorepo)"

# Publicar la rama main en GitHub
echo "⬆️ Enviando la rama main a GitHub..."
git push -u origin main

echo "========================================================"
echo "✅ ¡Rama 'main' creada y publicada con éxito en GitHub!"
echo "========================================================"
