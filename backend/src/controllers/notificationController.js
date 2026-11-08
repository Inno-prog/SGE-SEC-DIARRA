import prisma from '../config/prisma.js';
import { AppError, NotFoundError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createNotificationSchema,
  updateNotificationSchema,
  paginationSchema,
} from '../utils/validation.js';

export const getNotifications = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, isRead, type } = req.query;
    const skip = (page - 1) * limit;

    const where = { userId: req.user.id };
    if (isRead !== undefined) where.isRead = isRead === 'true';
    if (type) where.type = type;

    const [notifications, total] = await Promise.all([
      prisma.notification.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { createdAt: 'desc' },
      }),
      prisma.notification.count({ where }),
    ]);

    const unreadCount = await prisma.notification.count({
      where: { userId: req.user.id, isRead: false },
    });

    res.json({
      data: notifications,
      unreadCount,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const getNotificationById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const notification = await prisma.notification.findUnique({
      where: { id },
    });

    if (!notification) {
      throw new NotFoundError('Notification');
    }

    if (notification.userId !== req.user.id && req.user.role !== 'admin') {
      throw new AppError('Non autorisé', 403, 'AUTHORIZATION_ERROR');
    }

    res.json({ notification });
  } catch (error) {
    next(error);
  }
};

export const createNotification = async (req, res, next) => {
  try {
    const data = createNotificationSchema.parse(req.body);

    const user = await prisma.user.findUnique({ where: { id: data.userId } });
    if (!user) {
      throw new NotFoundError('Utilisateur');
    }

    const notification = await prisma.notification.create({
      data: {
        ...data,
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'ajout',
        collection: 'notifications',
        documentId: notification.id,
        description: `Notification envoyée à ${user.prenom} ${user.nom}`,
      },
    });

    res.status(201).json({ notification });
  } catch (error) {
    next(error);
  }
};

export const updateNotification = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateNotificationSchema.parse(req.body);

    const existing = await prisma.notification.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Notification');
    }

    if (existing.userId !== req.user.id && req.user.role !== 'admin') {
      throw new AppError('Non autorisé', 403, 'AUTHORIZATION_ERROR');
    }

    const notification = await prisma.notification.update({
      where: { id },
      data,
    });

    res.json({ notification });
  } catch (error) {
    next(error);
  }
};

export const markAsRead = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const notification = await prisma.notification.findUnique({ where: { id } });
    if (!notification) {
      throw new NotFoundError('Notification');
    }

    if (notification.userId !== req.user.id) {
      throw new AppError('Non autorisé', 403, 'AUTHORIZATION_ERROR');
    }

    await prisma.notification.update({
      where: { id },
      data: { isRead: true },
    });

    res.json({ message: 'Notification marquée comme lue' });
  } catch (error) {
    next(error);
  }
};

export const markAllAsRead = async (req, res, next) => {
  try {
    await prisma.notification.updateMany({
      where: { userId: req.user.id, isRead: false },
      data: { isRead: true },
    });

    res.json({ message: 'Toutes les notifications marquées comme lues' });
  } catch (error) {
    next(error);
  }
};

export const deleteNotification = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const notification = await prisma.notification.findUnique({ where: { id } });
    if (!notification) {
      throw new NotFoundError('Notification');
    }

    if (notification.userId !== req.user.id && req.user.role !== 'admin') {
      throw new AppError('Non autorisé', 403, 'AUTHORIZATION_ERROR');
    }

    await prisma.notification.delete({ where: { id } });

    res.json({ message: 'Notification supprimée avec succès' });
  } catch (error) {
    next(error);
  }
};