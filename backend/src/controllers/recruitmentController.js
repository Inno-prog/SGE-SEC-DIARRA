import prisma from '../config/prisma.js';
import { AppError, NotFoundError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createRecruitmentSchema,
  updateRecruitmentSchema,
  paginationSchema,
} from '../utils/validation.js';

export const getRecruitments = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, statut, departementId } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (statut) where.statut = statut;
    if (departementId) where.departementId = departementId;

    const [recruitments, total] = await Promise.all([
      prisma.recruitment.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { datePublication: 'desc' },
        include: {
          creator: { select: { id: true, nom: true, prenom: true } },
        },
      }),
      prisma.recruitment.count({ where }),
    ]);

    res.json({
      data: recruitments,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const getRecruitmentById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const recruitment = await prisma.recruitment.findUnique({
      where: { id },
      include: {
        creator: { select: { id: true, nom: true, prenom: true, email: true } },
      },
    });

    if (!recruitment) {
      throw new NotFoundError('Recrutement');
    }

    res.json({ recruitment });
  } catch (error) {
    next(error);
  }
};

export const createRecruitment = async (req, res, next) => {
  try {
    const data = createRecruitmentSchema.parse(req.body);

    const department = await prisma.department.findUnique({ where: { id: data.departementId } });
    if (!department) {
      throw new NotFoundError('Département');
    }

    const recruitment = await prisma.recruitment.create({
      data: {
        ...data,
        datePublication: new Date(data.datePublication),
        dateLimite: data.dateLimite ? new Date(data.dateLimite) : null,
        createdBy: req.user.id,
      },
      include: {
        creator: { select: { id: true, nom: true, prenom: true } },
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'ajout',
        collection: 'recruitments',
        documentId: recruitment.id,
        description: `Offre de recrutement: ${recruitment.poste}`,
      },
    });

    res.status(201).json({ recruitment });
  } catch (error) {
    next(error);
  }
};

export const updateRecruitment = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateRecruitmentSchema.parse(req.body);

    const existing = await prisma.recruitment.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Recrutement');
    }

    const updateData = { ...data };
    if (data.datePublication) updateData.datePublication = new Date(data.datePublication);
    if (data.dateLimite) updateData.dateLimite = new Date(data.dateLimite);

    const recruitment = await prisma.recruitment.update({
      where: { id },
      data: updateData,
      include: {
        creator: { select: { id: true, nom: true, prenom: true } },
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'modification',
        collection: 'recruitments',
        documentId: recruitment.id,
        description: `Mise à jour offre: ${recruitment.poste}`,
      },
    });

    res.json({ recruitment });
  } catch (error) {
    next(error);
  }
};

export const deleteRecruitment = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const recruitment = await prisma.recruitment.findUnique({ where: { id } });
    if (!recruitment) {
      throw new NotFoundError('Recrutement');
    }

    await prisma.recruitment.delete({ where: { id } });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'recruitments',
        documentId: id,
        description: `Suppression offre de recrutement`,
      },
    });

    res.json({ message: 'Offre de recrutement supprimée avec succès' });
  } catch (error) {
    next(error);
  }
};