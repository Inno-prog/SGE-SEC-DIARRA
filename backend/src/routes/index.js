import { Router } from 'express';
import authRoutes from './auth.js';
import userRoutes from './users.js';
import employeeRoutes from './employees.js';
import departmentRoutes from './departments.js';
import positionRoutes from './positions.js';
import contractRoutes from './contracts.js';
import attendanceRoutes from './attendances.js';
import leaveRoutes from './leaves.js';
import payrollRoutes from './payrolls.js';
import bonusRoutes from './bonuses.js';
import sanctionRoutes from './sanctions.js';
import trainingRoutes from './trainings.js';
import evaluationRoutes from './evaluations.js';
import documentRoutes from './documents.js';
import recruitmentRoutes from './recruitments.js';
import notificationRoutes from './notifications.js';
import conversationRoutes from './conversations.js';
import agendaRoutes from './agenda.js';
import scheduleRoutes from './schedules.js';
import auditRoutes from './audit.js';
import dashboardRoutes from './dashboard.js';

const router = Router();

// Public routes
router.use('/auth', authRoutes);

// Protected routes
router.use('/users', userRoutes);
router.use('/employees', employeeRoutes);
router.use('/departments', departmentRoutes);
router.use('/positions', positionRoutes);
router.use('/contracts', contractRoutes);
router.use('/attendances', attendanceRoutes);
router.use('/leaves', leaveRoutes);
router.use('/payrolls', payrollRoutes);
router.use('/bonuses', bonusRoutes);
router.use('/sanctions', sanctionRoutes);
router.use('/trainings', trainingRoutes);
router.use('/evaluations', evaluationRoutes);
router.use('/documents', documentRoutes);
router.use('/recruitments', recruitmentRoutes);
router.use('/notifications', notificationRoutes);
router.use('/conversations', conversationRoutes);
router.use('/agenda', agendaRoutes);
router.use('/schedules', scheduleRoutes);
router.use('/audit', auditRoutes);
router.use('/dashboard', dashboardRoutes);

export default router;