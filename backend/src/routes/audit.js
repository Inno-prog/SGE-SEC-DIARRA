import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as auditController from '../controllers/auditController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  auditQuerySchema,
  paginationSchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

router.use(authMiddleware);
router.use(requireRole('admin', 'manager'));

router.get('/', validateQuery(auditQuerySchema), auditController.getAuditLogs);
router.get('/stats', auditController.getAuditStats);
router.get('/:id', validateParams(idParamSchema), auditController.getAuditLogById);

export default router;