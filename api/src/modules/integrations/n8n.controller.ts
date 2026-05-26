import { Request, Response } from 'express';

export const handleN8nWebhook = (req: Request, res: Response) => {
  console.log('Webhook de n8n recibido:', req.body);
  // Lógica para procesar el webhook de n8n
  res.status(200).json({ message: 'Webhook de n8n procesado' });
};
