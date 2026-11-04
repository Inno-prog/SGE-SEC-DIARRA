import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as departmentController from '../controllers/departmentController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createDepartmentSchema,
  updateDepartmentSchema,
  paginationSchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

router.use(authMiddleware);

router.get('/', validateQuery(paginationSchema), departmentController.getDepartments);
router.get('/:id', validateParams(idParamSchema), departmentController.getDepartmentById);
router.post('/', requireRole('admin', 'manager', 'hr'), validate(createDepartmentSchema), departmentController.createDepartment);
router.patch('/:id', requireRole('admin', 'manager', 'hr'), validateParams(idParamSchema), validate(updateDepartmentSchema), departmentController.updateDepartment);
router.delete('/:id', requireRole('admin'), validateParams(idParamSchema), departmentController.deleteDepartment);

export default router;