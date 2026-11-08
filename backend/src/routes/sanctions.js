import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as sanctionController from '../controllers/sanctionController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createSanctionSchema,
  updateSanctionSchema,
  paginationSchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

router.use(authMiddleware);

router.get('/', validateQuery(paginationSchema), sanctionController.getSanctions);
router.get('/:id', validateParams(idParamSchema), sanctionController.getSanctionById);
router.post('/', requireRole('admin', 'manager', 'hr'), validate(createSanctionSchema), sanctionController.createSanction);
router.patch('/:id', requireRole('admin', 'manager', 'hr'), validateParams(idParamSchema), validate(updateSanctionSchema), sanctionController.updateSanction);
router.delete('/:id', requireRole('admin'), validateParams(idParamSchema), sanctionController.deleteSanction);

export default router;