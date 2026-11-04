import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as recruitmentController from '../controllers/recruitmentController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createRecruitmentSchema,
  updateRecruitmentSchema,
  paginationSchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

router.use(authMiddleware);

router.get('/', validateQuery(paginationSchema), recruitmentController.getRecruitments);
router.get('/:id', validateParams(idParamSchema), recruitmentController.getRecruitmentById);
router.post('/', requireRole('admin', 'manager', 'hr'), validate(createRecruitmentSchema), recruitmentController.createRecruitment);
router.patch('/:id', requireRole('admin', 'manager', 'hr'), validateParams(idParamSchema), validate(updateRecruitmentSchema), recruitmentController.updateRecruitment);
router.delete('/:id', requireRole('admin'), validateParams(idParamSchema), recruitmentController.deleteRecruitment);

export default router;