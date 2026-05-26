import { Request, Response } from 'express';

export const handleWooCommerceWebhook = (req: Request, res: Response) => {
  console.log('Webhook de WooCommerce recibido:', req.body);
  // Lógica para procesar el webhook de WooCommerce
  res.status(200).json({ message: 'Webhook de WooCommerce procesado' });
};
