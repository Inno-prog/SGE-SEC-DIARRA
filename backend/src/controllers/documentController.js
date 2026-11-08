import prisma from '../config/prisma.js';
import { AppError, NotFoundError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createDocumentSchema,
  updateDocumentSchema,
  paginationSchema,
} from '../utils/validation.js';
import path from 'path';
import fs from 'fs';

const UPLOAD_DIR = path.join(process.cwd(), 'uploads', 'documents');

// Ensure upload directory exists
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

export const getDocuments = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, employeeId, type } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (employeeId) where.employeeId = employeeId;
    if (type) where.type = type;

    const [documents, total] = await Promise.all([
      prisma.document.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { createdAt: 'desc' },
        include: {
          employee: { select: { id: true, matricule: true, nom: true, prenom: true } },
          creator: { select: { id: true, nom: true, prenom: true } },
        },
      }),
      prisma.document.count({ where }),
    ]);

    res.json({
      data: documents,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const getDocumentById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const document = await prisma.document.findUnique({
      where: { id },
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true, email: true } },
        creator: { select: { id: true, nom: true, prenom: true, email: true } },
      },
    });

    if (!document) {
      throw new NotFoundError('Document');
    }

    res.json({ document });
  } catch (error) {
    next(error);
  }
};

export const createDocument = async (req, res, next) => {
  try {
    const data = createDocumentSchema.parse(req.body);

    const employee = await prisma.employee.findUnique({ where: { id: data.employeeId } });
    if (!employee) {
      throw new NotFoundError('Employé');
    }

    const document = await prisma.document.create({
      data: {
        ...data,
        createdBy: req.user.id,
      },
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true } },
        creator: { select: { id: true, nom: true, prenom: true } },
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'ajout',
        collection: 'documents',
        documentId: document.id,
        description: `Document "${document.nom}" pour ${employee.prenom} ${employee.nom}`,
      },
    });

    res.status(201).json({ document });
  } catch (error) {
    next(error);
  }
};

export const updateDocument = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateDocumentSchema.parse(req.body);

    const existing = await prisma.document.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Document');
    }

    const document = await prisma.document.update({
      where: { id },
      data,
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true } },
        creator: { select: { id: true, nom: true, prenom: true } },
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'modification',
        collection: 'documents',
        documentId: document.id,
        description: `Mise à jour document pour ${document.employee.prenom} ${document.employee.nom}`,
      },
    });

    res.json({ document });
  } catch (error) {
    next(error);
  }
};

export const deleteDocument = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const document = await prisma.document.findUnique({ where: { id } });
    if (!document) {
      throw new NotFoundError('Document');
    }

    await prisma.document.delete({ where: { id } });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'documents',
        documentId: id,
        description: `Suppression document`,
      },
    });

    res.json({ message: 'Document supprimé avec succès' });
  } catch (error) {
    next(error);
  }
};

export const uploadDocument = async (req, res, next) => {
  try {
    console.log('=== UPLOAD DOCUMENT DEBUG ===');
    console.log('req.body:', JSON.stringify(req.body, null, 2));
    console.log('req.files:', req.files ? Object.keys(req.files) : 'undefined');
    if (req.files && req.files.file) {
      console.log('req.files.file[0]:', {
        fieldname: req.files.file[0].fieldname,
        originalname: req.files.file[0].originalname,
        encoding: req.files.file[0].encoding,
        mimetype: req.files.file[0].mimetype,
        size: req.files.file[0].size,
      });
    }
    console.log('Content-Type:', req.headers['content-type']);
    console.log('==============================');

    // Handle file from upload.fields() - it's in req.files.file[0]
    const file = req.files && req.files.file ? req.files.file[0] : null;

    if (!file) {
      throw new AppError('Aucun fichier fourni', 400, 'NO_FILE');
    }

    const { employeeId, type, nom } = req.body;

    if (!employeeId || !type) {
      console.log('MISSING FIELDS - employeeId:', employeeId, 'type:', type);
      throw new AppError('employeeId et type sont requis', 400, 'MISSING_FIELDS');
    }

    // Verify employee exists - try by UUID first, then by matricule
    let employee = await prisma.employee.findUnique({ where: { id: employeeId } });
    if (!employee) {
      // Try finding by matricule
      employee = await prisma.employee.findUnique({ where: { matricule: employeeId } });
    }
    if (!employee) {
      throw new NotFoundError('Employé');
    }

    // Generate unique filename
    const ext = path.extname(file.originalname);
    const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}${ext}`;
    const filePath = path.join(UPLOAD_DIR, fileName);

    // Save file to disk
    fs.writeFileSync(filePath, file.buffer);

    // Create document record with file URL
    const fileUrl = `/uploads/documents/${fileName}`;
    const document = await prisma.document.create({
      data: {
        employeeId,
        employeeNom: `${employee.prenom} ${employee.nom}`,
        type,
        nom: nom || file.originalname,
        url: fileUrl,
        tailleFichier: file.size,
        createdBy: req.user.id,
      },
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true } },
        creator: { select: { id: true, nom: true, prenom: true } },
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'ajout',
        collection: 'documents',
        documentId: document.id,
        description: `Upload document "${document.nom}" pour ${employee.prenom} ${employee.nom}`,
      },
    });

    res.status(201).json({ document });
  } catch (error) {
    next(error);
  }
};