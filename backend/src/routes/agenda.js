import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as agendaController from '../controllers/agendaController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createAgendaSchema,
  updateAgendaSchema,
  paginationSchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

router.use(authMiddleware);

router.get('/', validateQuery(paginationSchema), agendaController.getAgendaEvents);
router.get('/upcoming', agendaController.getUpcomingEvents);
router.get('/:id', validateParams(idParamSchema), agendaController.getAgendaEventById);
router.post('/', validate(createAgendaSchema), agendaController.createAgendaEvent);
router.patch('/:id', validateParams(idParamSchema), validate(updateAgendaSchema), agendaController.updateAgendaEvent);
router.delete('/:id', validateParams(idParamSchema), agendaController.deleteAgendaEvent);

export default router;