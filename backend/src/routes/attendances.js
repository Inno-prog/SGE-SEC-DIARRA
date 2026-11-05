import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as attendanceController from '../controllers/attendanceController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createAttendanceSchema,
  updateAttendanceSchema,
  attendanceQuerySchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

router.use(authMiddleware);

router.get('/', validateQuery(attendanceQuerySchema), attendanceController.getAttendances);
router.get('/today', attendanceController.getTodayAttendances);
router.get('/:id', validateParams(idParamSchema), attendanceController.getAttendanceById);
router.post('/', requireRole('admin', 'manager', 'hr'), validate(createAttendanceSchema), attendanceController.createAttendance);
router.patch('/:id', requireRole('admin', 'manager', 'hr'), validateParams(idParamSchema), validate(updateAttendanceSchema), attendanceController.updateAttendance);
router.delete('/:id', requireRole('admin'), validateParams(idParamSchema), attendanceController.deleteAttendance);

export default router;