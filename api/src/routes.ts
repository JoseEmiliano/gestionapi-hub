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
