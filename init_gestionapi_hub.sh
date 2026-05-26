#!/bin/bash

BASE="/home/kempa/proyectos/gestionapi-hub"

echo "🚀 Creando GestionAPI Hub en: $BASE"

mkdir -p "$BASE"
cd "$BASE"

# 1. Carpetas base
mkdir -p api/src/{config,core/{middleware,prisma},modules/{integrations,customers,sales},routes}
mkdir -p api/prisma
mkdir -p infra/docker
mkdir -p automations/n8n
mkdir -p docs/architecture
mkdir -p services

################################
# 2. package.json (API)
################################
cat << 'EOF' > api/package.json
{
  "name": "gestionapi-hub",
  "version": "1.0.0",
  "main": "dist/server.js",
  "scripts": {
    "dev": "ts-node-dev --respawn src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js"
  },
  "dependencies": {
    "@prisma/client": "5.22.0",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "express": "^4.18.2",
    "jsonwebtoken": "^9.0.2"
  },
  "devDependencies": {
    "prisma": "5.22.0",
    "ts-node-dev": "^2.0.0",
    "typescript": "^5.3.3",
    "@types/express": "^4.17.21",
    "@types/cors": "^2.8.17",
    "@types/jsonwebtoken": "^9.0.5"
  }
}
EOF

################################
# 3. tsconfig
################################
cat << 'EOF' > api/tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "CommonJS",
    "rootDir": "src",
    "outDir": "dist",
    "strict": true,
    "esModuleInterop": true
  }
}
EOF

################################
# 4. Prisma schema
################################
cat << 'EOF' > api/prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model IntegrationEvent {
  id        Int      @id @default(autoincrement())
  source    String   // woocommerce, nextcloud, mercadopago, n8n, etc
  type      String   // order.created, file.updated, payment.approved, etc
  payload   Json
  status    String   @default("received") // received, processed, failed
  createdAt DateTime @default(now())
}

model Customer {
  id        Int      @id @default(autoincrement())
  externalId String? // id en Dolibarr / WooCommerce
  name      String
  email     String?
  phone     String?
  createdAt DateTime @default(now())
}

model Sale {
  id         Int      @id @default(autoincrement())
  externalId String?  // id de pedido WooCommerce
  customer   Customer @relation(fields: [customerId], references: [id])
  customerId Int
  total      Float
  source     String   // woocommerce, manual, etc
  createdAt  DateTime @default(now())
}
EOF

################################
# 5. Core: Prisma client
################################
cat << 'EOF' > api/src/core/prisma/client.ts
import { PrismaClient } from "@prisma/client";

export const prisma = new PrismaClient();
EOF

################################
# 6. Config env
################################
cat << 'EOF' > api/src/config/env.ts
import dotenv from "dotenv";
dotenv.config();

export const env = {
  PORT: process.env.PORT || 4000,
  DATABASE_URL: process.env.DATABASE_URL!,
  JWT_SECRET: process.env.JWT_SECRET || "supersecret"
};
EOF

################################
# 7. Middleware de errores
################################
cat << 'EOF' > api/src/core/middleware/errorHandler.ts
import { Request, Response, NextFunction } from "express";

export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  console.error("❌ Error:", err);
  res.status(500).json({ error: err.message || "Internal Server Error" });
};
EOF

################################
# 8. App y server
################################
cat << 'EOF' > api/src/app.ts
import express from "express";
import cors from "cors";
import { errorHandler } from "./core/middleware/errorHandler";
import { router } from "./routes";

const app = express();
app.use(cors());
app.use(express.json());

app.use("/api", router);
app.use(errorHandler);

export default app;
EOF

cat << 'EOF' > api/src/server.ts
import app from "./app";
import { env } from "./config/env";

app.listen(env.PORT, () => {
  console.log("🚀 GestionAPI Hub corriendo en puerto", env.PORT);
});
EOF

################################
# 9. Router principal
################################
cat << 'EOF' > api/src/routes.ts
import { Router } from "express";
import { integrationsRouter } from "./modules/integrations/integrations.routes";

export const router = Router();

router.use("/integrations", integrationsRouter);
EOF

################################
# 10. Módulo de integraciones (webhooks hub)
################################
mkdir -p api/src/modules/integrations

cat << 'EOF' > api/src/modules/integrations/integrations.routes.ts
import { Router } from "express";
import { handleWooWebhook } from "./woo.controller";
import { handleN8nWebhook } from "./n8n.controller";

export const integrationsRouter = Router();

// Webhook WooCommerce
integrationsRouter.post("/webhooks/woocommerce", handleWooWebhook);

// Webhook n8n (puente para otras automatizaciones)
integrationsRouter.post("/webhooks/n8n", handleN8nWebhook);
EOF

cat << 'EOF' > api/src/modules/integrations/woo.controller.ts
import { Request, Response } from "express";
import { prisma } from "../../core/prisma/client";

export const handleWooWebhook = async (req: Request, res: Response) => {
  const event = await prisma.integrationEvent.create({
    data: {
      source: "woocommerce",
      type: req.headers["x-wc-webhook-event"]?.toString() || "unknown",
      payload: req.body,
    },
  });

  console.log("📦 WooCommerce event recibido:", event.id);
  res.json({ ok: true });
};
EOF

cat << 'EOF' > api/src/modules/integrations/n8n.controller.ts
import { Request, Response } from "express";
import { prisma } from "../../core/prisma/client";

export const handleN8nWebhook = async (req: Request, res: Response) => {
  const event = await prisma.integrationEvent.create({
    data: {
      source: "n8n",
      type: req.body.type || "generic",
      payload: req.body,
    },
  });

  console.log("🤖 n8n event recibido:", event.id);
  res.json({ ok: true });
};
EOF

################################
# 11. Docker Compose (API + DB + n8n)
################################
cat << 'EOF' > infra/docker/docker-compose.yml
services:
  api:
    build: ../../api
    container_name: gestionapi-hub-api
    ports:
      - "4000:4000"
    environment:
      DATABASE_URL: postgres://postgres:postgres@db:5432/gestionapi_hub
      JWT_SECRET: supersecret
    depends_on:
      - db

  db:
    image: postgres:15
    container_name: gestionapi-hub-db
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: gestionapi_hub
    ports:
      - "5433:5432"
    volumes:
      - db_data:/var/lib/postgresql/data

  n8n:
    image: n8nio/n8n
    container_name: gestionapi-hub-n8n
    ports:
      - "5678:5678"
    environment:
      N8N_BASIC_AUTH_ACTIVE: "false"
      GENERIC_TIMEZONE: "America/Argentina/Buenos_Aires"

volumes:
  db_data:
EOF

################################
# 12. Dockerfile API
################################
cat << 'EOF' > api/Dockerfile
FROM node:20

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run build

EXPOSE 4000
CMD ["npm", "start"]
EOF

################################
# 13. Script local
################################
mkdir -p scripts

cat << 'EOF' > scripts/local_setup.sh
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
EOF

chmod +x scripts/local_setup.sh

echo "🎉 GestionAPI Hub generado en $BASE"
echo "👉 Para correr local: bash $BASE/scripts/local_setup.sh"
EOF
