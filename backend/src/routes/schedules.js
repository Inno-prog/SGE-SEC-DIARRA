import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as scheduleController from '../controllers/scheduleController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createScheduleSchema,
  updateScheduleSchema,
  paginationSchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

router.use(authMiddleware);

router.get('/', validateQuery(paginationSchema), scheduleController.getSchedules);
router.get('/:id', validateParams(idParamSchema), scheduleController.getScheduleById);
router.post('/', requireRole('admin', 'manager', 'hr'), validate(createScheduleSchema), scheduleController.createSchedule);
router.patch('/:id', requireRole('admin', 'manager', 'hr'), validateParams(idParamSchema), validate(updateScheduleSchema), scheduleController.updateSchedule);
router.delete('/:id', requireRole('admin'), validateParams(idParamSchema), scheduleController.deleteSchedule);

export default router;