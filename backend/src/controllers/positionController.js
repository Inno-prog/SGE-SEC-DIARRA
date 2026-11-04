import prisma from '../config/prisma.js';
import { AppError, NotFoundError, ConflictError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createPositionSchema,
  updatePositionSchema,
  paginationSchema,
} from '../utils/validation.js';

export const getPositions = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, departementId, search } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (departementId) where.departementId = departementId;
    if (search) {
      where.OR = [
        { titre: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [positions, total] = await Promise.all([
      prisma.position.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { titre: 'asc' },
        include: {
          departement: { select: { id: true, nom: true } },
          _count: { select: { employees: true } },
        },
      }),
      prisma.position.count({ where }),
    ]);

    res.json({
      data: positions,
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

export const getPositionById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const position = await prisma.position.findUnique({
      where: { id },
      include: {
        departement: { select: { id: true, nom: true } },
        employees: {
          select: {
            id: true,
            matricule: true,
            nom: true,
            prenom: true,
            email: true,
            salaire: true,
          },
        },
      },
    });

    if (!position) {
      throw new NotFoundError('Poste');
    }

    res.json({ position });
  } catch (error) {
    next(error);
  }
};

export const createPosition = async (req, res, next) => {
  try {
    const data = createPositionSchema.parse(req.body);

    // Verify department exists if provided
    if (data.departementId) {
      const department = await prisma.department.findUnique({
        where: { id: data.departementId },
      });
      if (!department) {
        throw new NotFoundError('Département');
      }
    }

    const position = await prisma.position.create({
      data: {
        titre: data.titre,
        description: data.description,
        departementId: data.departementId,
        salaireMini: data.salaireMini,
        salaireMaxi: data.salaireMaxi,
      },
      include: {
        departement: { select: { id: true, nom: true } },
        _count: { select: { employees: true } },
      },
    });

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'ajout',
        collection: 'positions',
        documentId: position.id,
        description: `Création du poste ${position.titre}`,
      },
    });

    res.status(201).json({ position });
  } catch (error) {
    next(error);
  }
};

export const updatePosition = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updatePositionSchema.parse(req.body);

    const existing = await prisma.position.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Poste');
    }

    // Verify department exists if changing
    if (data.departementId && data.departementId !== existing.departementId) {
      const department = await prisma.department.findUnique({
        where: { id: data.departementId },
      });
      if (!department) {
        throw new NotFoundError('Département');
      }
    }

    const position = await prisma.position.update({
      where: { id },
      data: {
        titre: data.titre,
        description: data.description,
        departementId: data.departementId,
        salaireMini: data.salaireMini,
        salaireMaxi: data.salaireMaxi,
      },
      include: {
        departement: { select: { id: true, nom: true } },
        _count: { select: { employees: true } },
      },
    });

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'modification',
        collection: 'positions',
        documentId: position.id,
        description: `Mise à jour du poste ${position.titre}`,
      },
    });

    res.json({ position });
  } catch (error) {
    next(error);
  }
};

export const deletePosition = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const position = await prisma.position.findUnique({
      where: { id },
      include: { _count: { select: { employees: true } } },
    });
    if (!position) {
      throw new NotFoundError('Poste');
    }

    if (position._count.employees > 0) {
      throw new AppError('Impossible de supprimer un poste avec des employés', 400, 'HAS_EMPLOYEES');
    }

    await prisma.position.delete({ where: { id } });

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'positions',
        documentId: id,
        description: `Suppression du poste ${position.titre}`,
      },
    });

    res.json({ message: 'Poste supprimé avec succès' });
  } catch (error) {
    next(error);
  }
};