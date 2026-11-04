import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as bonusController from '../controllers/bonusController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createBonusSchema,
  updateBonusSchema,
  paginationSchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

router.use(authMiddleware);

router.get('/', validateQuery(paginationSchema), bonusController.getBonuses);
router.get('/:id', validateParams(idParamSchema), bonusController.getBonusById);
router.post('/', requireRole('admin', 'manager', 'hr'), validate(createBonusSchema), bonusController.createBonus);
router.patch('/:id', requireRole('admin', 'manager', 'hr'), validateParams(idParamSchema), validate(updateBonusSchema), bonusController.updateBonus);
router.delete('/:id', requireRole('admin'), validateParams(idParamSchema), bonusController.deleteBonus);

export default router;