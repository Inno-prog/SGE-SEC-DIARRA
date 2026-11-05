import prisma from '../config/prisma.js';
import { AppError, NotFoundError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createScheduleSchema,
  updateScheduleSchema,
  paginationSchema,
} from '../utils/validation.js';

export const getSchedules = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, type } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (type) where.type = type;

    const [schedules, total] = await Promise.all([
      prisma.schedule.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { createdAt: 'desc' },
        include: {
          creator: { select: { id: true, nom: true, prenom: true } },
        },
      }),
      prisma.schedule.count({ where }),
    ]);

    res.json({
      data: schedules,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const getScheduleById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const schedule = await prisma.schedule.findUnique({
      where: { id },
      include: {
        creator: { select: { id: true, nom: true, prenom: true, email: true } },
      },
    });

    if (!schedule) {
      throw new NotFoundError('Planning');
    }

    res.json({ schedule });
  } catch (error) {
    next(error);
  }
};

export const createSchedule = async (req, res, next) => {
  try {
    const data = createScheduleSchema.parse(req.body);

    const schedule = await prisma.schedule.create({
      data: {
        ...data,
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
        collection: 'schedules',
        documentId: schedule.id,
        description: `Planning: ${schedule.nom}`,
      },
    });

    res.status(201).json({ schedule });
  } catch (error) {
    next(error);
  }
};

export const updateSchedule = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateScheduleSchema.parse(req.body);

    const existing = await prisma.schedule.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Planning');
    }

    const schedule = await prisma.schedule.update({
      where: { id },
      data,
      include: {
        creator: { select: { id: true, nom: true, prenom: true } },
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'modification',
        collection: 'schedules',
        documentId: schedule.id,
        description: `Mise à jour planning: ${schedule.nom}`,
      },
    });

    res.json({ schedule });
  } catch (error) {
    next(error);
  }
};

export const deleteSchedule = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const schedule = await prisma.schedule.findUnique({ where: { id } });
    if (!schedule) {
      throw new NotFoundError('Planning');
    }

    await prisma.schedule.delete({ where: { id } });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'schedules',
        documentId: id,
        description: `Suppression planning`,
      },
    });

    res.json({ message: 'Planning supprimé avec succès' });
  } catch (error) {
    next(error);
  }
};