#!/bin/bash

BASE="/home/kempa/proyectos/gestionapi-hub"

echo "🚀 Iniciando GestionAPI Hub (local)..."

cd "$BASE/api"
npm install
npx prisma generate
npx prisma migrate dev --name init

cd "$BASE/infra/docker"
docker compose up -d --build

cd "$BASE/api"
npm run dev
