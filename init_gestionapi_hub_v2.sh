#!/bin/bash

# ==============================================================================
# Script: init_gestionapi_hub_v2.sh
# Description: Inicializa la estructura completa del proyecto GestionAPI Hub,
#              incluyendo directorios, archivos base, configuración de Docker
#              y dependencias.
# Author: GitHub Copilot
# Version: 2.0
# ==============================================================================

# --- Banner de Inicio ---
echo "🚀 Inicializando el ecosistema de GestionAPI Hub v2..."
echo "------------------------------------------------------------------"

# --- 1. Creación de la Estructura de Directorios ---
echo "📂 Creando estructura de directorios..."
mkdir -p api/src/routes
mkdir -p api/src/modules/integrations
mkdir -p api/src/modules/customers
mkdir -p api/src/modules/sales
mkdir -p api/src/core/middleware
mkdir -p api/src/core/prisma
mkdir -p api/src/config
mkdir -p infra/docker
mkdir -p scripts
mkdir -p automations/n8n
mkdir -p docs/architecture
mkdir -p services

echo "✅ Estructura de directorios creada."
echo "------------------------------------------------------------------"

# --- 2. Creación de Archivos de Configuración y Código Base ---
echo "📄 Creando archivos base y de configuración..."

# --- API: package.json ---
cat <<'EOF' > api/package.json
{
  "name": "gestionapi-hub-api",
  "version": "1.0.0",
  "description": "API central para GestionAPI Hub",
  "main": "dist/server.js",
  "scripts": {
    "dev": "ts-node-dev --respawn --transpile-only src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev",
    "prisma:studio": "prisma studio"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "express": "^4.18.2",
    "dotenv": "^16.3.1",
    "@prisma/client": "^5.10.2"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/node": "^20.11.24",
    "prisma": "^5.10.2",
    "ts-node-dev": "^2.0.0",
    "typescript": "^5.3.3"
  }
}
EOF

# --- API: tsconfig.json ---
cat <<'EOF' > api/tsconfig.json
{
  "compilerOptions": {
    "target": "es2021",
    "module": "commonjs",
    "rootDir": "./src",
    "outDir": "./dist",
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "strict": true,
    "skipLibCheck": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

# --- API: .env.example ---
cat <<'EOF' > api/.env.example
# Configuración de la Base de Datos (PostgreSQL)
DATABASE_URL="postgresql://user:password@localhost:5432/gestionapi_hub?schema=public"

# Puerto de la API
PORT=3000
EOF

# --- API: Dockerfile ---
cat <<'EOF' > api/Dockerfile
FROM node:18

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

EXPOSE 3000
CMD [ "node", "dist/server.js" ]
EOF

# --- API: Prisma Schema ---
cat <<'EOF' > api/prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Customer {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
EOF

# --- API: src/app.ts ---
cat <<'EOF' > api/src/app.ts
import express from 'express';
import { loadRoutes } from './routes';
import { errorHandler } from './core/middleware/errorHandler';

const app = express();

app.use(express.json());

// Cargar rutas principales
loadRoutes(app);

// Middleware de manejo de errores
app.use(errorHandler);

export default app;
EOF

# --- API: src/server.ts ---
cat <<'EOF' > api/src/server.ts
import app from './app';
import { env } from './config/env';

const PORT = env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});
EOF

# --- API: src/routes.ts ---
cat <<'EOF' > api/src/routes.ts
import { Application, Router } from 'express';
import integrationsRouter from './modules/integrations/integrations.routes';

const _routes: Array<[string, Router]> = [
  ['/integrations', integrationsRouter],
];

export const loadRoutes = (app: Application) => {
  _routes.forEach(([path, controller]) => {
    app.use(path, controller);
  });
};
EOF

# --- API: src/config/env.ts ---
cat <<'EOF' > api/src/config/env.ts
import dotenv from 'dotenv';
dotenv.config();

export const env = {
  DATABASE_URL: process.env.DATABASE_URL,
  PORT: process.env.PORT,
};
EOF

# --- API: src/core/prisma/client.ts ---
cat <<'EOF' > api/src/core/prisma/client.ts
import { PrismaClient } from '@prisma/client';

export const prisma = new PrismaClient();
EOF

# --- API: src/core/middleware/errorHandler.ts ---
cat <<'EOF' > api/src/core/middleware/errorHandler.ts
import { Request, Response, NextFunction } from 'express';

export const errorHandler = (err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error(err.stack);
  res.status(500).send({ error: 'Algo salió mal!' });
};
EOF

# --- API: src/modules/integrations/integrations.routes.ts ---
cat <<'EOF' > api/src/modules/integrations/integrations.routes.ts
import { Router } from 'express';
import { handleN8nWebhook } from './n8n.controller';
import { handleWooCommerceWebhook } from './woo.controller';

const router = Router();

router.post('/n8n-webhook', handleN8nWebhook);
router.post('/woo-webhook', handleWooCommerceWebhook);

export default router;
EOF

# --- API: src/modules/integrations/n8n.controller.ts ---
cat <<'EOF' > api/src/modules/integrations/n8n.controller.ts
import { Request, Response } from 'express';

export const handleN8nWebhook = (req: Request, res: Response) => {
  console.log('Webhook de n8n recibido:', req.body);
  // Lógica para procesar el webhook de n8n
  res.status(200).json({ message: 'Webhook de n8n procesado' });
};
EOF

# --- API: src/modules/integrations/woo.controller.ts ---
cat <<'EOF' > api/src/modules/integrations/woo.controller.ts
import { Request, Response } from 'express';

export const handleWooCommerceWebhook = (req: Request, res: Response) => {
  console.log('Webhook de WooCommerce recibido:', req.body);
  // Lógica para procesar el webhook de WooCommerce
  res.status(200).json({ message: 'Webhook de WooCommerce procesado' });
};
EOF

# --- Infra: docker-compose.yml ---
cat <<'EOF' > infra/docker/docker-compose.yml
version: '3.8'

services:
  api:
    build:
      context: ../../api
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
    depends_on:
      - db
    volumes:
      - ../../api:/usr/src/app
      - /usr/src/app/node_modules

  db:
    image: postgres:14
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=gestionapi_hub
    volumes:
      - postgres_data:/var/lib/postgresql/data

  n8n:
    image: n8nio/n8n
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - NODE_ENV=production
      - WEBHOOK_URL=http://localhost:5678/
    volumes:
      - n8n_data:/home/node/.n8n

volumes:
  postgres_data:
  n8n_data:
EOF

echo "✅ Archivos base creados."
echo "------------------------------------------------------------------"

# --- 3. Hacer el script ejecutable ---
chmod +x init_gestionapi_hub_v2.sh

# --- Banner Final ---
echo "🎉 ¡El script init_gestionapi_hub_v2.sh ha sido creado y está listo!"
echo "Ahora puedes ejecutarlo para configurar todo el entorno."
echo "------------------------------------------------------------------"

