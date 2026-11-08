import prisma from '../config/prisma.js';
import { AppError, NotFoundError, ConflictError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createDepartmentSchema,
  updateDepartmentSchema,
  paginationSchema,
} from '../utils/validation.js';

export const getDepartments = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, search } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (search) {
      where.OR = [
        { nom: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [departments, total] = await Promise.all([
      prisma.department.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { nom: 'asc' },
        include: {
          responsable: { select: { id: true, nom: true, prenom: true, email: true } },
          _count: { select: { employees: true, positions: true } },
        },
      }),
      prisma.department.count({ where }),
    ]);

    res.json({
      data: departments,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    next(error);
  }
};

export const getDepartmentById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const department = await prisma.department.findUnique({
      where: { id },
      include: {
        responsable: { select: { id: true, nom: true, prenom: true, email: true } },
        employees: {
          select: {
            id: true,
            matricule: true,
            nom: true,
            prenom: true,
            poste: true,
            email: true,
            statut: true,
          },
        },
        positions: {
          select: {
            id: true,
            titre: true,
            description: true,
            salaireMini: true,
            salaireMaxi: true,
          },
        },
      },
    });

    if (!department) {
      throw new NotFoundError('Département');
    }

    res.json({ department });
  } catch (error) {
    next(error);
  }
};

export const createDepartment = async (req, res, next) => {
  try {
    const data = createDepartmentSchema.parse(req.body);

    // Check if department name already exists
    const existing = await prisma.department.findFirst({
      where: { nom: data.nom },
    });
    if (existing) {
      throw new ConflictError('Ce nom de département existe déjà');
    }

    // Verify responsable exists if provided
    let responsableId = data.responsableId?.trim() === '' ? null : data.responsableId;

    // Validate UUID format if provided
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (responsableId && !uuidRegex.test(responsableId)) {
      console.warn('Invalid UUID format for responsableId:', responsableId);
      responsableId = null;
    }

    if (responsableId) {
      const responsable = await prisma.user.findUnique({
        where: { id: responsableId },
      });
      if (!responsable) {
        console.warn('Responsable not found, setting to null:', responsableId);
        responsableId = null;
      }
    }

    const department = await prisma.department.create({
      data: {
        nom: data.nom,
        description: data.description,
        responsableId: responsableId,
      },
      include: {
        responsable: { select: { id: true, nom: true, prenom: true, email: true } },
        _count: { select: { employees: true, positions: true } },
      },
    });

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'ajout',
        collection: 'departments',
        documentId: department.id,
        description: `Création du département ${department.nom}`,
      },
    });

    res.status(201).json({ department });
  } catch (error) {
    next(error);
  }
};

export const updateDepartment = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateDepartmentSchema.parse(req.body);

    const existing = await prisma.department.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Département');
    }

    // Check name uniqueness if changing
    if (data.nom && data.nom !== existing.nom) {
      const nameExists = await prisma.department.findFirst({
        where: { nom: data.nom },
      });
      if (nameExists) {
        throw new ConflictError('Ce nom de département existe déjà');
      }
    }

    // Verify responsable exists if changing (handle empty string as null)
    let responsableId = data.responsableId?.trim() === '' ? null : data.responsableId;

    // Validate UUID format if provided
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (responsableId && !uuidRegex.test(responsableId)) {
      console.warn('Invalid UUID format for responsableId:', responsableId);
      responsableId = null;
    }

    if (responsableId && responsableId !== existing.responsableId) {
      const responsable = await prisma.user.findUnique({
        where: { id: responsableId },
      });
      if (!responsable) {
        // Don't throw error, just set to null (allows clearing invalid responsable)
        console.warn('Responsable not found, setting to null:', responsableId);
        responsableId = null;
      }
    }

    const department = await prisma.department.update({
      where: { id },
      data: {
        nom: data.nom,
        description: data.description,
        responsableId: responsableId,
      },
      include: {
        responsable: { select: { id: true, nom: true, prenom: true, email: true } },
        _count: { select: { employees: true, positions: true } },
      },
    });

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'modification',
        collection: 'departments',
        documentId: department.id,
        description: `Mise à jour du département ${department.nom}`,
      },
    });

    res.json({ department });
  } catch (error) {
    next(error);
  }
};

export const deleteDepartment = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const department = await prisma.department.findUnique({
      where: { id },
      include: { _count: { select: { employees: true } } },
    });
    if (!department) {
      throw new NotFoundError('Département');
    }

    if (department._count.employees > 0) {
      throw new AppError('Impossible de supprimer un département avec des employés', 400, 'HAS_EMPLOYEES');
    }

    await prisma.department.delete({ where: { id } });

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'departments',
        documentId: id,
        description: `Suppression du département ${department.nom}`,
      },
    });

    res.json({ message: 'Département supprimé avec succès' });
  } catch (error) {
    next(error);
  }
};