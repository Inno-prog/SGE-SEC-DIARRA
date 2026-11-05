import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as trainingController from '../controllers/trainingController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createTrainingSchema,
  updateTrainingSchema,
  paginationSchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

router.use(authMiddleware);

router.get('/', validateQuery(paginationSchema), trainingController.getTrainings);
router.get('/:id', validateParams(idParamSchema), trainingController.getTrainingById);
router.post('/', requireRole('admin', 'manager', 'hr'), validate(createTrainingSchema), trainingController.createTraining);
router.patch('/:id', requireRole('admin', 'manager', 'hr'), validateParams(idParamSchema), validate(updateTrainingSchema), trainingController.updateTraining);
router.delete('/:id', requireRole('admin'), validateParams(idParamSchema), trainingController.deleteTraining);

export default router;