import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as userController from '../controllers/userController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createUserSchema,
  updateUserSchema,
  paginationSchema,
  idParamSchema,
  updateUserStatusSchema,
} from '../utils/validation.js';

const router = Router();

// All routes require authentication
router.use(authMiddleware);

// Get all users (admin, manager, hr)
router.get('/', requireRole('admin', 'manager', 'hr'), validateQuery(paginationSchema), userController.getUsers);

// Get user by ID
router.get('/:id', validateParams(idParamSchema), userController.getUserById);

// Create user (admin only)
router.post('/', requireRole('admin'), validate(createUserSchema), userController.createUser);

// Update user (admin only)
router.patch('/:id', requireRole('admin'), validateParams(idParamSchema), validate(updateUserSchema), userController.updateUser);

// Update user status (admin only)
router.patch('/:id/status', requireRole('admin'), validateParams(idParamSchema), validate(updateUserStatusSchema), userController.updateUserStatus);

// Delete user (admin only)
router.delete('/:id', requireRole('admin'), validateParams(idParamSchema), userController.deleteUser);

// Reset user password (admin only)
router.post('/:id/reset-password', requireRole('admin'), validateParams(idParamSchema), userController.resetUserPassword);

export default router;