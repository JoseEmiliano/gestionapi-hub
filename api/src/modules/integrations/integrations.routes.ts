import { Router } from 'express';
import { handleN8nWebhook } from './n8n.controller';
import { handleWooCommerceWebhook } from './woo.controller';

const router = Router();

router.post('/n8n-webhook', handleN8nWebhook);
router.post('/woo-webhook', handleWooCommerceWebhook);

export default router;
