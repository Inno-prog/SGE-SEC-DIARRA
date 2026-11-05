import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as employeeController from '../controllers/employeeController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createEmployeeSchema,
  updateEmployeeSchema,
  employeeQuerySchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

// All routes require authentication
router.use(authMiddleware);

// Get all employees
router.get('/', validateQuery(employeeQuerySchema), employeeController.getEmployees);

// Get employee stats (admin, manager, hr)
router.get('/stats', requireRole('admin', 'manager', 'hr'), employeeController.getEmployeeStats);

// Get birthdays this month
router.get('/birthdays', employeeController.getBirthdaysThisMonth);

// Generate matricule
router.get('/generate-matricule', employeeController.generateMatricule);

// Get employee by ID
router.get('/:id', validateParams(idParamSchema), employeeController.getEmployeeById);

// Create employee (admin, manager, hr)
router.post('/', requireRole('admin', 'manager', 'hr'), validate(createEmployeeSchema), employeeController.createEmployee);

// Update employee (admin, manager, hr)
router.patch('/:id', requireRole('admin', 'manager', 'hr'), validateParams(idParamSchema), validate(updateEmployeeSchema), employeeController.updateEmployee);

// Delete employee (admin only)
router.delete('/:id', requireRole('admin'), validateParams(idParamSchema), employeeController.deleteEmployee);

export default router;