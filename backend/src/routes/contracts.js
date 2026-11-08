import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as contractController from '../controllers/contractController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createContractSchema,
  updateContractSchema,
  contractQuerySchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

router.use(authMiddleware);

router.get('/', validateQuery(contractQuerySchema), contractController.getContracts);
router.get('/expiring', contractController.getExpiringContracts);
router.get('/:id', validateParams(idParamSchema), contractController.getContractById);
router.post('/', requireRole('admin', 'manager', 'hr'), validate(createContractSchema), contractController.createContract);
router.patch('/:id', requireRole('admin', 'manager', 'hr'), validateParams(idParamSchema), validate(updateContractSchema), contractController.updateContract);
router.delete('/:id', requireRole('admin'), validateParams(idParamSchema), contractController.deleteContract);

export default router;