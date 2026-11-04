import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import * as authController from '../controllers/authController.js';
import { validate, validateQuery } from '../utils/validation.js';
import {
  loginSchema,
  registerSchema,
  refreshTokenSchema,
  changePasswordSchema,
  resetPasswordSchema,
  updateProfileSchema,
} from '../utils/validation.js';

const router = Router();

// Public routes
router.post('/login', validate(loginSchema), authController.login);
router.post('/register', validate(registerSchema), authController.register);
router.post('/refresh', validate(refreshTokenSchema), authController.refreshToken);
router.post('/logout', authController.logout);
router.post('/password/reset', validate(resetPasswordSchema), authController.requestPasswordReset);

// Protected routes
router.get('/verify', authMiddleware, authController.verifyAuth);
router.get('/profile', authMiddleware, authController.getProfile);
router.patch('/profile', authMiddleware, validate(updateProfileSchema), authController.updateProfile);
router.post('/password/change', authMiddleware, validate(changePasswordSchema), authController.changePassword);

export default router;