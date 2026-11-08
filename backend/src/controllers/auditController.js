import prisma from '../config/prisma.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import { auditQuerySchema, paginationSchema } from '../utils/validation.js';

export const getAuditLogs = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, userId, action, collection, dateDebut, dateFin } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (userId) where.userId = userId;
    if (action) where.action = action;
    if (collection) where.collection = collection;
    if (dateDebut || dateFin) {
      where.createdAt = {};
      if (dateDebut) where.createdAt.gte = new Date(dateDebut);
      if (dateFin) where.createdAt.lte = new Date(dateFin);
    }

    const [logs, total] = await Promise.all([
      prisma.auditLog.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { createdAt: 'desc' },
        include: {
          user: { select: { id: true, nom: true, prenom: true, email: true } },
        },
      }),
      prisma.auditLog.count({ where }),
    ]);

    res.json({
      data: logs,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const getAuditLogById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const log = await prisma.auditLog.findUnique({
      where: { id },
      include: {
        user: { select: { id: true, nom: true, prenom: true, email: true } },
      },
    });

    if (!log) {
      throw new AppError('Log d\'audit non trouvé', 404, 'NOT_FOUND');
    }

    res.json({ log });
  } catch (error) {
    next(error);
  }
};

export const getAuditStats = async (req, res, next) => {
  try {
    const [total, byAction, byCollection, recentActivity] = await Promise.all([
      prisma.auditLog.count(),
      prisma.auditLog.groupBy({ by: ['action'], _count: true }),
      prisma.auditLog.groupBy({ by: ['collection'], _count: true }),
      prisma.auditLog.findMany({
        take: 10,
        orderBy: { createdAt: 'desc' },
        include: { user: { select: { nom: true, prenom: true } } },
      }),
    ]);

    res.json({
      total,
      byAction: byAction.map(a => ({ action: a.action, count: a._count })),
      byCollection: byCollection.map(c => ({ collection: c.collection, count: c._count })),
      recentActivity,
    });
  } catch (error) {
    next(error);
  }
};

import { AppError } from '../middleware/errorHandler.js';