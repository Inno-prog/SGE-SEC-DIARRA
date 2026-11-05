import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as notificationController from '../controllers/notificationController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createNotificationSchema,
  updateNotificationSchema,
  paginationSchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

router.use(authMiddleware);

router.get('/', validateQuery(paginationSchema), notificationController.getNotifications);
router.get('/:id', validateParams(idParamSchema), notificationController.getNotificationById);
router.post('/', requireRole('admin', 'manager', 'hr'), validate(createNotificationSchema), notificationController.createNotification);
router.patch('/:id', validateParams(idParamSchema), validate(updateNotificationSchema), notificationController.updateNotification);
router.patch('/:id/read', validateParams(idParamSchema), notificationController.markAsRead);
router.patch('/read-all', notificationController.markAllAsRead);
router.delete('/:id', validateParams(idParamSchema), notificationController.deleteNotification);

export default router;