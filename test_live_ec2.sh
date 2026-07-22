#!/bin/bash
HOST="http://3.226.156.228"
echo "=== 1. Obteniendo Token de Administrador ==="
TOKEN=$(curl -s -X POST "$HOST/api/auth/login" -H "Content-Type: application/json" -d '{"matricula":"000000","contrasena":"admin1"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

if [ -z "$TOKEN" ]; then
  echo "Fallo al obtener el token. Asegúrate de que el seeder funcionó."
  exit 1
fi

echo "Token obtenido correctamente."

echo -e "\n=== 2. Creando Reportes de Prueba (Simulando Flutter) ==="
# Obtenemos id_aula 1
curl -s -X POST "$HOST/api/reportes" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"titulo": "El clima no funciona", "descripcion": "Hace mucho calor y el AC no enciende.", "id_aula": 1}' > /dev/null
curl -s -X POST "$HOST/api/reportes" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"titulo": "Falla de aire", "descripcion": "Sigue sin enfriar el minisplit.", "id_aula": 1}' > /dev/null
curl -s -X POST "$HOST/api/reportes" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"titulo": "Pizarrón roto", "descripcion": "El pizarrón está rayado y agrietado.", "id_aula": 2}' > /dev/null

echo "Reportes creados."

echo -e "\n=== 3. Probando Topic Modeling (Clustering) ==="
curl -s -X GET "$HOST/api/reportes/clustering" -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

echo -e "\n=== 4. Probando Motor de Búsqueda Semántica ==="
curl -s -X GET "$HOST/api/catalogo?buscar=programacion" | python3 -m json.tool | head -n 25

echo -e "\n=== 5. Probando Sistema de Recomendación ==="
curl -s -X GET "$HOST/api/eventos/recomendados" -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

