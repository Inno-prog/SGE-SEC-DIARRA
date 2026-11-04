import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as payrollController from '../controllers/payrollController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createPayrollSchema,
  updatePayrollSchema,
  payrollQuerySchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

router.use(authMiddleware);

router.get('/', validateQuery(payrollQuerySchema), payrollController.getPayrolls);
router.post('/generate', requireRole('admin', 'manager', 'hr'), payrollController.generatePayroll);
router.get('/:id', validateParams(idParamSchema), payrollController.getPayrollById);
router.post('/', requireRole('admin', 'manager', 'hr'), validate(createPayrollSchema), payrollController.createPayroll);
router.patch('/:id', requireRole('admin', 'manager', 'hr'), validateParams(idParamSchema), validate(updatePayrollSchema), payrollController.updatePayroll);
router.delete('/:id', requireRole('admin'), validateParams(idParamSchema), payrollController.deletePayroll);

export default router;