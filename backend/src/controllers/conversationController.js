import prisma from '../config/prisma.js';
import { AppError, NotFoundError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createConversationSchema,
  updateConversationSchema,
  createMessageSchema,
  updateMessageSchema,
  paginationSchema,
} from '../utils/validation.js';

export const getConversations = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder } = req.query;
    const skip = (page - 1) * limit;

    const conversations = await prisma.conversation.findMany({
      where: {
        participants: {
          some: { userId: req.user.id },
        },
      },
      skip,
      take: limit,
      orderBy: sortBy ? { [sortBy]: sortOrder } : { lastMessageAt: 'desc' },
      include: {
        participants: {
          include: {
            user: { select: { id: true, nom: true, prenom: true, photoUrl: true } },
          },
        },
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
          include: {
            sender: { select: { id: true, nom: true, prenom: true } },
          },
        },
      },
    });

    const total = await prisma.conversation.count({
      where: {
        participants: {
          some: { userId: req.user.id },
        },
      },
    });

    res.json({
      data: conversations,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const getConversationById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const conversation = await prisma.conversation.findUnique({
      where: { id },
      include: {
        participants: {
          include: {
            user: { select: { id: true, nom: true, prenom: true, photoUrl: true, email: true } },
          },
        },
        messages: {
          orderBy: { createdAt: 'asc' },
          include: {
            sender: { select: { id: true, nom: true, prenom: true, photoUrl: true } },
          },
        },
      },
    });

    if (!conversation) {
      throw new NotFoundError('Conversation');
    }

    // Check if user is participant
    const isParticipant = conversation.participants.some(p => p.userId === req.user.id);
    if (!isParticipant && req.user.role !== 'admin') {
      throw new AppError('Non autorisé', 403, 'AUTHORIZATION_ERROR');
    }

    res.json({ conversation });
  } catch (error) {
    next(error);
  }
};

export const createConversation = async (req, res, next) => {
  try {
    const data = createConversationSchema.parse(req.body);

    // Ensure current user is in participants
    if (!data.participantIds.includes(req.user.id)) {
      data.participantIds.push(req.user.id);
    }

    const conversation = await prisma.conversation.create({
      data: {
        nom: data.nom,
        participants: {
          create: data.participantIds.map(userId => ({ userId })),
        },
      },
      include: {
        participants: {
          include: {
            user: { select: { id: true, nom: true, prenom: true, photoUrl: true } },
          },
        },
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'ajout',
        collection: 'conversations',
        documentId: conversation.id,
        description: `Création conversation: ${conversation.nom}`,
      },
    });

    res.status(201).json({ conversation });
  } catch (error) {
    next(error);
  }
};

export const updateConversation = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateConversationSchema.parse(req.body);

    const conversation = await prisma.conversation.findUnique({ where: { id } });
    if (!conversation) {
      throw new NotFoundError('Conversation');
    }

    const isParticipant = await prisma.conversationParticipant.findFirst({
      where: { conversationId: id, userId: req.user.id },
    });
    if (!isParticipant && req.user.role !== 'admin') {
      throw new AppError('Non autorisé', 403, 'AUTHORIZATION_ERROR');
    }

    const updated = await prisma.conversation.update({
      where: { id },
      data: { nom: data.nom },
      include: {
        participants: {
          include: {
            user: { select: { id: true, nom: true, prenom: true, photoUrl: true } },
          },
        },
      },
    });

    res.json({ conversation: updated });
  } catch (error) {
    next(error);
  }
};

export const deleteConversation = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const conversation = await prisma.conversation.findUnique({ where: { id } });
    if (!conversation) {
      throw new NotFoundError('Conversation');
    }

    await prisma.conversation.delete({ where: { id } });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'conversations',
        documentId: id,
        description: `Suppression conversation`,
      },
    });

    res.json({ message: 'Conversation supprimée avec succès' });
  } catch (error) {
    next(error);
  }
};

export const getMessages = async (req, res, next) => {
  try {
    const { conversationId } = req.params;
    const { page, limit, sortBy, sortOrder } = req.query;
    const skip = (page - 1) * limit;

    const conversation = await prisma.conversation.findUnique({ where: { id: conversationId } });
    if (!conversation) {
      throw new NotFoundError('Conversation');
    }

    const isParticipant = await prisma.conversationParticipant.findFirst({
      where: { conversationId, userId: req.user.id },
    });
    if (!isParticipant && req.user.role !== 'admin') {
      throw new AppError('Non autorisé', 403, 'AUTHORIZATION_ERROR');
    }

    const [messages, total] = await Promise.all([
      prisma.message.findMany({
        where: { conversationId },
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { createdAt: 'asc' },
        include: {
          sender: { select: { id: true, nom: true, prenom: true, photoUrl: true } },
        },
      }),
      prisma.message.count({ where: { conversationId } }),
    ]);

    res.json({
      data: messages,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const sendMessage = async (req, res, next) => {
  try {
    const { conversationId } = req.params;
    const data = createMessageSchema.parse(req.body);

    const conversation = await prisma.conversation.findUnique({ where: { id: conversationId } });
    if (!conversation) {
      throw new NotFoundError('Conversation');
    }

    const isParticipant = await prisma.conversationParticipant.findFirst({
      where: { conversationId, userId: req.user.id },
    });
    if (!isParticipant && req.user.role !== 'admin') {
      throw new AppError('Non autorisé', 403, 'AUTHORIZATION_ERROR');
    }

    const message = await prisma.message.create({
      data: {
        ...data,
        conversationId,
        senderId: req.user.id,
        senderNom: `${req.user.prenom} ${req.user.nom}`,
        senderPhoto: req.user.photoUrl || null,
      },
      include: {
        sender: { select: { id: true, nom: true, prenom: true, photoUrl: true } },
      },
    });

    // Update conversation last message
    await prisma.conversation.update({
      where: { id: conversationId },
      data: {
        lastMessage: data.contenu,
        lastMessageAt: new Date(),
      },
    });

    // Notify other participants
    const participants = await prisma.conversationParticipant.findMany({
      where: { conversationId, userId: { not: req.user.id } },
      select: { userId: true },
    });

    for (const p of participants) {
      await prisma.notification.create({
        data: {
          userId: p.userId,
          titre: 'Nouveau message',
          message: `${req.user.prenom} ${req.user.nom}: ${data.contenu.substring(0, 50)}...`,
          type: 'info',
          actionRoute: `/conversations/${conversationId}`,
        },
      });
    }

    res.status(201).json({ message });
  } catch (error) {
    next(error);
  }
};

export const markMessageRead = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const message = await prisma.message.findUnique({ where: { id } });
    if (!message) {
      throw new NotFoundError('Message');
    }

    if (message.senderId === req.user.id) {
      throw new AppError('Cannot mark own message as read', 400, 'INVALID_ACTION');
    }

    await prisma.message.update({
      where: { id },
      data: { isRead: true },
    });

    res.json({ message: 'Message marqué comme lu' });
  } catch (error) {
    next(error);
  }
};