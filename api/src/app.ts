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
