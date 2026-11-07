import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as leaveController from '../controllers/leaveController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createLeaveSchema,
  updateLeaveSchema,
  updateLeaveStatusSchema,
  leaveQuerySchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

router.use(authMiddleware);

router.get('/', validateQuery(leaveQuerySchema), leaveController.getLeaves);
router.get('/pending', requireRole('admin', 'manager', 'hr'), leaveController.getPendingLeaves);
router.get('/:id', validateParams(idParamSchema), leaveController.getLeaveById);
router.post('/', validate(createLeaveSchema), leaveController.createLeave);
router.patch('/:id', requireRole('admin', 'manager', 'hr'), validateParams(idParamSchema), validate(updateLeaveSchema), leaveController.updateLeave);
router.patch('/:id/status', requireRole('admin', 'manager', 'hr'), validateParams(idParamSchema), validate(updateLeaveStatusSchema), leaveController.updateLeaveStatus);
router.delete('/:id', requireRole('admin'), validateParams(idParamSchema), leaveController.deleteLeave);

export default router;