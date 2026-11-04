import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as evaluationController from '../controllers/evaluationController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createEvaluationSchema,
  updateEvaluationSchema,
  paginationSchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

router.use(authMiddleware);

router.get('/', validateQuery(paginationSchema), evaluationController.getEvaluations);
router.get('/:id', validateParams(idParamSchema), evaluationController.getEvaluationById);
router.post('/', requireRole('admin', 'manager', 'hr'), validate(createEvaluationSchema), evaluationController.createEvaluation);
router.patch('/:id', requireRole('admin', 'manager', 'hr'), validateParams(idParamSchema), validate(updateEvaluationSchema), evaluationController.updateEvaluation);
router.delete('/:id', requireRole('admin'), validateParams(idParamSchema), evaluationController.deleteEvaluation);

export default router;