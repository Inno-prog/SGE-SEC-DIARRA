import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as positionController from '../controllers/positionController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createPositionSchema,
  updatePositionSchema,
  paginationSchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

router.use(authMiddleware);

router.get('/', validateQuery(paginationSchema), positionController.getPositions);
router.get('/:id', validateParams(idParamSchema), positionController.getPositionById);
router.post('/', requireRole('admin', 'manager', 'hr'), validate(createPositionSchema), positionController.createPosition);
router.patch('/:id', requireRole('admin', 'manager', 'hr'), validateParams(idParamSchema), validate(updatePositionSchema), positionController.updatePosition);
router.delete('/:id', requireRole('admin'), validateParams(idParamSchema), positionController.deletePosition);

export default router;