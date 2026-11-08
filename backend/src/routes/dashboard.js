import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as dashboardController from '../controllers/dashboardController.js';

const router = Router();

router.use(authMiddleware);

router.get('/stats', dashboardController.getDashboardStats);
router.get('/charts', dashboardController.getDashboardCharts);

export default router;