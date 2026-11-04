import prisma from '../config/prisma.js';
import { AppError, NotFoundError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createTrainingSchema,
  updateTrainingSchema,
  paginationSchema,
} from '../utils/validation.js';

export const getTrainings = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, employeeId } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (employeeId) where.employeeId = employeeId;

    const [trainings, total] = await Promise.all([
      prisma.training.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { date: 'desc' },
        include: {
          employee: { select: { id: true, matricule: true, nom: true, prenom: true } },
          creator: { select: { id: true, nom: true, prenom: true } },
        },
      }),
      prisma.training.count({ where }),
    ]);

    res.json({
      data: trainings,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const getTrainingById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const training = await prisma.training.findUnique({
      where: { id },
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true, email: true } },
        creator: { select: { id: true, nom: true, prenom: true, email: true } },
      },
    });

    if (!training) {
      throw new NotFoundError('Formation');
    }

    res.json({ training });
  } catch (error) {
    next(error);
  }
};

export const createTraining = async (req, res, next) => {
  try {
    const data = createTrainingSchema.parse(req.body);

    const employee = await prisma.employee.findUnique({ where: { id: data.employeeId } });
    if (!employee) {
      throw new NotFoundError('Employé');
    }

    const training = await prisma.training.create({
      data: {
        ...data,
        date: new Date(data.date),
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
        collection: 'trainings',
        documentId: training.id,
        description: `Formation pour ${employee.prenom} ${employee.nom} - ${data.intitule}`,
      },
    });

    res.status(201).json({ training });
  } catch (error) {
    next(error);
  }
};

export const updateTraining = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateTrainingSchema.parse(req.body);

    const existing = await prisma.training.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Formation');
    }

    const updateData = { ...data };
    if (data.date) updateData.date = new Date(data.date);

    const training = await prisma.training.update({
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
        collection: 'trainings',
        documentId: training.id,
        description: `Mise à jour formation pour ${training.employee.prenom} ${training.employee.nom}`,
      },
    });

    res.json({ training });
  } catch (error) {
    next(error);
  }
};

export const deleteTraining = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const training = await prisma.training.findUnique({ where: { id } });
    if (!training) {
      throw new NotFoundError('Formation');
    }

    await prisma.training.delete({ where: { id } });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'trainings',
        documentId: id,
        description: `Suppression formation`,
      },
    });

    res.json({ message: 'Formation supprimée avec succès' });
  } catch (error) {
    next(error);
  }
};