import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// Ruta raíz
app.get('/', (req, res) => {
  res.json({
    message: 'API GestionCloud funcionando correctamente',
    version: '1.0.0'
  });
});

// Healthcheck
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Puerto dinámico (requerido para EasyPanel / Railway)
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});
