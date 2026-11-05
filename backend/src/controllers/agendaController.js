import prisma from '../config/prisma.js';
import { AppError, NotFoundError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createAgendaSchema,
  updateAgendaSchema,
  paginationSchema,
} from '../utils/validation.js';

export const getAgendaEvents = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, from, to, type } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (type) where.type = type;
    if (from || to) {
      where.dateDebut = {};
      if (from) where.dateDebut.gte = new Date(from);
      if (to) where.dateDebut.lte = new Date(to);
    }

    const [events, total] = await Promise.all([
      prisma.agenda.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { dateDebut: 'asc' },
        include: {
          creator: { select: { id: true, nom: true, prenom: true } },
        },
      }),
      prisma.agenda.count({ where }),
    ]);

    res.json({
      data: events,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const getAgendaEventById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const event = await prisma.agenda.findUnique({
      where: { id },
      include: {
        creator: { select: { id: true, nom: true, prenom: true, email: true } },
      },
    });

    if (!event) {
      throw new NotFoundError('Événement');
    }

    res.json({ event });
  } catch (error) {
    next(error);
  }
};

export const createAgendaEvent = async (req, res, next) => {
  try {
    const data = createAgendaSchema.parse(req.body);

    const event = await prisma.agenda.create({
      data: {
        ...data,
        dateDebut: new Date(data.dateDebut),
        dateFin: new Date(data.dateFin),
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
        collection: 'agenda',
        documentId: event.id,
        description: `Événement: ${event.titre}`,
      },
    });

    // Notify participants
    if (data.participants && data.participants.length > 0) {
      for (const participantId of data.participants) {
        const user = await prisma.user.findUnique({ where: { id: participantId } });
        if (user) {
          await prisma.notification.create({
            data: {
              userId: participantId,
              titre: 'Nouvel événement',
              message: `Vous êtes invité à "${event.titre}" le ${event.dateDebut.toLocaleDateString()}`,
              type: 'info',
              actionRoute: `/agenda/${event.id}`,
            },
          });
        }
      }
    }

    res.status(201).json({ event });
  } catch (error) {
    next(error);
  }
};

export const updateAgendaEvent = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateAgendaSchema.parse(req.body);

    const existing = await prisma.agenda.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Événement');
    }

    const updateData = { ...data };
    if (data.dateDebut) updateData.dateDebut = new Date(data.dateDebut);
    if (data.dateFin) updateData.dateFin = new Date(data.dateFin);

    const event = await prisma.agenda.update({
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
        collection: 'agenda',
        documentId: event.id,
        description: `Mise à jour événement: ${event.titre}`,
      },
    });

    res.json({ event });
  } catch (error) {
    next(error);
  }
};

export const deleteAgendaEvent = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const event = await prisma.agenda.findUnique({ where: { id } });
    if (!event) {
      throw new NotFoundError('Événement');
    }

    await prisma.agenda.delete({ where: { id } });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'agenda',
        documentId: id,
        description: `Suppression événement`,
      },
    });

    res.json({ message: 'Événement supprimé avec succès' });
  } catch (error) {
    next(error);
  }
};

export const getUpcomingEvents = async (req, res, next) => {
  try {
    const now = new Date();
    const weekFromNow = new Date();
    weekFromNow.setDate(now.getDate() + 7);

    const events = await prisma.agenda.findMany({
      where: {
        dateDebut: { gte: now, lte: weekFromNow },
      },
      orderBy: { dateDebut: 'asc' },
      include: {
        creator: { select: { id: true, nom: true, prenom: true } },
      },
    });

    res.json({ events });
  } catch (error) {
    next(error);
  }
};