import express from 'express';
import cors from 'cors';

import authRoutes from './routes/auth.js';
import passengerRoutes from './routes/passenger.js';
import usersRoutes from './routes/users.js';
import entitiesRoutes from './routes/entities.js';
import contractsRoutes from './routes/contracts.js';
import trainsRoutes from './routes/trains.js';
import runInstancesRoutes from './routes/runInstances.js';
import coachFormsRoutes from './routes/coachForms.js';
import premisesFormsRoutes from './routes/premisesForms.js';
import ctsFormsRoutes from './routes/ctsForms.js';
import stationRoutes from './routes/station.js';
import obhsRoutes from './routes/obhs.js';
import mediaRoutes from './routes/media.js';
import reportsRoutes from './routes/reports.js';
import dashboardRoutes from './routes/dashboard.js';
import tasksRoutes from './routes/tasks.js';
import v2Routes from './routes/v2.js';
import billingRoutes from './routes/billing.js';
import cleaningFormRoutes from './routes/cleaningForm.js';
import miscRoutes from './routes/misc.js';
import { notFoundHandler, errorHandler } from './middleware/errorHandler.js';

const app = express();

// ─── CORS: Must be first middleware ──────────────────────────────────────────
// Allows Flutter Web (localhost) and Flutter APK to call Render backend
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
  credentials: false,
}));

// Handle browser OPTIONS preflight immediately
app.options('*', (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type,Authorization,X-Requested-With,Accept');
  res.status(204).end();
});

// Safety-net: set ACAO header on every response
app.use((req, res, next) => {
  res.set('Access-Control-Allow-Origin', '*');
  next();
});

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

app.get('/', (req, res) => res.send('Swachh Railways API is running.'));

// Mount all route modules
app.use(authRoutes);
app.use(passengerRoutes);
app.use(usersRoutes);
app.use(entitiesRoutes);
app.use(contractsRoutes);
app.use(trainsRoutes);
app.use(runInstancesRoutes);
app.use(coachFormsRoutes);
app.use(premisesFormsRoutes);
app.use(ctsFormsRoutes);
app.use(stationRoutes);
app.use(obhsRoutes);
app.use(mediaRoutes);
app.use(reportsRoutes);
app.use(dashboardRoutes);
app.use(tasksRoutes);
app.use(v2Routes);
app.use(billingRoutes);
app.use(cleaningFormRoutes);
app.use(miscRoutes);

// Error handling
app.use(notFoundHandler);
app.use(errorHandler);

export default app;
