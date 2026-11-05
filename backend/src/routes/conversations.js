import { Router } from 'express';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as conversationController from '../controllers/conversationController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createConversationSchema,
  updateConversationSchema,
  createMessageSchema,
  updateMessageSchema,
  paginationSchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();

router.use(authMiddleware);

router.get('/', validateQuery(paginationSchema), conversationController.getConversations);
router.get('/:id', validateParams(idParamSchema), conversationController.getConversationById);
router.post('/', validate(createConversationSchema), conversationController.createConversation);
router.patch('/:id', validateParams(idParamSchema), validate(updateConversationSchema), conversationController.updateConversation);
router.delete('/:id', validateParams(idParamSchema), conversationController.deleteConversation);

// Messages
router.get('/:conversationId/messages', validateParams(idParamSchema), validateQuery(paginationSchema), conversationController.getMessages);
router.post('/:conversationId/messages', validateParams(idParamSchema), validate(createMessageSchema), conversationController.sendMessage);
router.patch('/messages/:id/read', validateParams(idParamSchema), conversationController.markMessageRead);

export default router;