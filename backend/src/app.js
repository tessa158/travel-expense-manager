import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import session from 'express-session';
import MySQLStoreFactory from 'express-mysql-session';
import { env } from './config/env.js';
import routes from './routes/index.js';
import { apiLimiter } from './middleware/rateLimit.js';
import { errorHandler, notFound } from './middleware/errorHandler.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const MySQLStore = MySQLStoreFactory(session);

export function createApp() {
  const app = express();
  app.disable('x-powered-by');
  if (env.isProd) app.set('trust proxy', 1); // needed for secure cookies behind a reverse proxy

  app.use(
    helmet({
      contentSecurityPolicy: {
        directives: {
          ...helmet.contentSecurityPolicy.getDefaultDirectives(),
          'upgrade-insecure-requests': null, // the app may be served over plain http on localhost
          'style-src': ["'self'", 'https:', "'unsafe-inline'"],
          'font-src': ["'self'", 'https:', 'data:'],
          'img-src': ["'self'", 'data:', 'blob:'],
        },
      },
    })
  );
  app.use(cors({ origin: env.clientOrigin, credentials: true }));
  app.use(express.json({ limit: '100kb' }));

  const store = new MySQLStore({
    host: env.db.host,
    port: env.db.port,
    user: env.db.user,
    password: env.db.password,
    database: env.db.database,
    createDatabaseTable: false, // the "sessions" table is created by database/schema.sql
    clearExpired: true,
    checkExpirationInterval: 15 * 60 * 1000,
    expiration: env.sessionMaxAgeMs,
  });

  app.use(
    session({
      name: 'tem.sid',
      secret: env.sessionSecret,
      store,
      resave: false,
      saveUninitialized: false,
      rolling: true,
      cookie: {
        httpOnly: true, // JavaScript in the browser cannot read the cookie
        sameSite: 'lax', // blocks cross-site form posts (CSRF)
        secure: env.isProd, // HTTPS only in production
        maxAge: env.sessionMaxAgeMs,
      },
    })
  );

  app.use('/api', apiLimiter, routes);
  app.use('/api', notFound);

  // Optional: serve the built React app (npm run build in /frontend) from the same server.
  const dist = path.resolve(__dirname, '../../frontend/dist');
  if (fs.existsSync(path.join(dist, 'index.html'))) {
    app.use(express.static(dist));
    app.get('*', (req, res) => res.sendFile(path.join(dist, 'index.html')));
  }

  app.use(errorHandler);
  return app;
}
