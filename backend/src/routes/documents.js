import { Router } from 'express';
import multer from 'multer';
import { authMiddleware, requireRole } from '../middleware/auth.js';
import * as documentController from '../controllers/documentController.js';
import { validate, validateQuery, validateParams } from '../utils/validation.js';
import {
  createDocumentSchema,
  updateDocumentSchema,
  paginationSchema,
  idParamSchema,
} from '../utils/validation.js';

const router = Router();
// Use multer with memory storage and parse all fields
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }
});

// Use upload.none() to parse form fields without files, and upload.single('file') for file uploads
// We'll use a custom middleware that handles both
const parseMultipart = upload.fields([
  { name: 'file', maxCount: 1 },
  { name: 'employeeId', maxCount: 1 },
  { name: 'type', maxCount: 1 },
  { name: 'nom', maxCount: 1 },
]);

router.use(authMiddleware);

router.get('/', validateQuery(paginationSchema), documentController.getDocuments);
router.get('/:id', validateParams(idParamSchema), documentController.getDocumentById);
router.post('/', requireRole('admin', 'manager', 'hr'), validate(createDocumentSchema), documentController.createDocument);
router.post('/upload', requireRole('admin', 'manager', 'hr'), parseMultipart, documentController.uploadDocument);
router.patch('/:id', requireRole('admin', 'manager', 'hr'), validateParams(idParamSchema), validate(updateDocumentSchema), documentController.updateDocument);
router.delete('/:id', requireRole('admin'), validateParams(idParamSchema), documentController.deleteDocument);

export default router;