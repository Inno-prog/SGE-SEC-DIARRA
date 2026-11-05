import prisma from '../config/prisma.js';
import { AppError, NotFoundError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createBonusSchema,
  updateBonusSchema,
  paginationSchema,
} from '../utils/validation.js';

export const getBonuses = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, employeeId, statut } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (employeeId) where.employeeId = employeeId;
    if (statut) where.statut = statut;

    const [bonuses, total] = await Promise.all([
      prisma.bonus.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { dateAttribution: 'desc' },
        include: {
          employee: { select: { id: true, matricule: true, nom: true, prenom: true } },
          creator: { select: { id: true, nom: true, prenom: true } },
        },
      }),
      prisma.bonus.count({ where }),
    ]);

    res.json({
      data: bonuses,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const getBonusById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const bonus = await prisma.bonus.findUnique({
      where: { id },
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true, email: true } },
        creator: { select: { id: true, nom: true, prenom: true, email: true } },
      },
    });

    if (!bonus) {
      throw new NotFoundError('Prime');
    }

    res.json({ bonus });
  } catch (error) {
    next(error);
  }
};

export const createBonus = async (req, res, next) => {
  try {
    const data = createBonusSchema.parse(req.body);

    const employee = await prisma.employee.findUnique({ where: { id: data.employeeId } });
    if (!employee) {
      throw new NotFoundError('Employé');
    }

    const bonus = await prisma.bonus.create({
      data: {
        ...data,
        dateAttribution: new Date(data.dateAttribution),
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
        collection: 'bonuses',
        documentId: bonus.id,
        description: `Attribution de prime à ${employee.prenom} ${employee.nom} - ${data.montant}`,
      },
    });

    res.status(201).json({ bonus });
  } catch (error) {
    next(error);
  }
};

export const updateBonus = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateBonusSchema.parse(req.body);

    const existing = await prisma.bonus.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Prime');
    }

    const updateData = { ...data };
    if (data.dateAttribution) updateData.dateAttribution = new Date(data.dateAttribution);

    const bonus = await prisma.bonus.update({
      where: { id },
      data: updateData,
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
        collection: 'bonuses',
        documentId: bonus.id,
        description: `Mise à jour prime pour ${bonus.employee.prenom} ${bonus.employee.nom}`,
      },
    });

    res.json({ bonus });
  } catch (error) {
    next(error);
  }
};

export const deleteBonus = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const bonus = await prisma.bonus.findUnique({ where: { id } });
    if (!bonus) {
      throw new NotFoundError('Prime');
    }

    await prisma.bonus.delete({ where: { id } });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'bonuses',
        documentId: id,
        description: `Suppression prime`,
      },
    });

    res.json({ message: 'Prime supprimée avec succès' });
  } catch (error) {
    next(error);
  }
};