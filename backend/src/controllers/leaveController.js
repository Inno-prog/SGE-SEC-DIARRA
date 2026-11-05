import prisma from '../config/prisma.js';
import { AppError, NotFoundError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createLeaveSchema,
  updateLeaveSchema,
  leaveQuerySchema,
} from '../utils/validation.js';

export const getLeaves = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, employeeId, statut, type } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (employeeId) where.employeeId = employeeId;
    if (statut) where.statut = statut;
    if (type) where.type = type;

    const [leaves, total] = await Promise.all([
      prisma.leave.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { dateDebut: 'desc' },
        include: {
          employee: { select: { id: true, matricule: true, nom: true, prenom: true } },
          creator: { select: { id: true, nom: true, prenom: true } },
        },
      }),
      prisma.leave.count({ where }),
    ]);

    res.json({
      data: leaves,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const getLeaveById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const leave = await prisma.leave.findUnique({
      where: { id },
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true, email: true, soldeCongesAnnuels: true, soldeCongesMaladie: true } },
        creator: { select: { id: true, nom: true, prenom: true, email: true } },
      },
    });

    if (!leave) {
      throw new NotFoundError('Congé');
    }

    res.json({ leave });
  } catch (error) {
    next(error);
  }
};

export const createLeave = async (req, res, next) => {
  try {
    const data = createLeaveSchema.parse(req.body);

    const employee = await prisma.employee.findUnique({ where: { id: data.employeeId } });
    if (!employee) {
      throw new NotFoundError('Employé');
    }

    // Check leave balance
    if (data.type === 'annuel' && employee.soldeCongesAnnuels < data.nombreJours) {
      throw new AppError('Solde de congés annuels insuffisant', 400, 'INSUFFICIENT_BALANCE');
    }
    if (data.type === 'maladie' && employee.soldeCongesMaladie < data.nombreJours) {
      throw new AppError('Solde de congés maladie insuffisant', 400, 'INSUFFICIENT_BALANCE');
    }

    const leave = await prisma.leave.create({
      data: {
        ...data,
        dateDebut: new Date(data.dateDebut),
        dateFin: new Date(data.dateFin),
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
        collection: 'leaves',
        documentId: leave.id,
        description: `Demande de congé pour ${employee.prenom} ${employee.nom}`,
      },
    });

    // Create notification for HR/managers
    const managers = await prisma.user.findMany({
      where: { role: { in: ['admin', 'manager', 'hr'] }, isActive: true },
      select: { id: true },
    });

    for (const manager of managers) {
      await prisma.notification.create({
        data: {
          userId: manager.id,
          titre: 'Nouvelle demande de congé',
          message: `${employee.prenom} ${employee.nom} a demandé un congé ${data.type} du ${data.dateDebut} au ${data.dateFin}`,
          type: 'leave_request',
          actionRoute: `/leaves/${leave.id}`,
        },
      });
    }

    res.status(201).json({ leave });
  } catch (error) {
    next(error);
  }
};

export const updateLeave = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateLeaveSchema.parse(req.body);

    const existing = await prisma.leave.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Congé');
    }

    const updateData = { ...data };
    if (data.dateDebut) updateData.dateDebut = new Date(data.dateDebut);
    if (data.dateFin) updateData.dateFin = new Date(data.dateFin);
    if (data.statut === 'approuve' && existing.statut !== 'approuve') {
      updateData.dateValidation = new Date();
      updateData.validePar = req.user.id;
    }

    const leave = await prisma.leave.update({
      where: { id },
      data: updateData,
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true, email: true } },
        creator: { select: { id: true, nom: true, prenom: true } },
      },
    });

    // Update leave balances if approved
    if (data.statut === 'approuve' && existing.statut !== 'approuve') {
      const employee = await prisma.employee.findUnique({ where: { id: leave.employeeId } });
      if (employee) {
        if (leave.type === 'annuel') {
          await prisma.employee.update({
            where: { id: leave.employeeId },
            data: { soldeCongesAnnuels: { decrement: leave.nombreJours } },
          });
        } else if (leave.type === 'maladie') {
          await prisma.employee.update({
            where: { id: leave.employeeId },
            data: { soldeCongesMaladie: { decrement: leave.nombreJours } },
          });
        }
      }
    }

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'modification',
        collection: 'leaves',
        documentId: leave.id,
        description: `Mise à jour congé pour ${leave.employee.prenom} ${leave.employee.nom} - Statut: ${leave.statut}`,
      },
    });

    // Notify employee of status change
    if (data.statut && data.statut !== existing.statut) {
      const employeeUser = await prisma.user.findFirst({
        where: { employeeId: leave.employeeId },
        select: { id: true },
      });
      if (employeeUser) {
        await prisma.notification.create({
          data: {
            userId: employeeUser.id,
            titre: 'Mise à jour de votre demande de congé',
            message: `Votre demande de congé a été ${data.statut === 'approuve' ? 'approuvée' : data.statut === 'rejete' ? 'rejetée' : 'mise à jour'}`,
            type: 'leave_request',
            actionRoute: `/leaves/${leave.id}`,
          },
        });
      }
    }

    res.json({ leave });
  } catch (error) {
    next(error);
  }
};

export const deleteLeave = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const leave = await prisma.leave.findUnique({ where: { id } });
    if (!leave) {
      throw new NotFoundError('Congé');
    }

    // Restore leave balance if it was approved
    if (leave.statut === 'approuve') {
      const employee = await prisma.employee.findUnique({ where: { id: leave.employeeId } });
      if (employee) {
        if (leave.type === 'annuel') {
          await prisma.employee.update({
            where: { id: leave.employeeId },
            data: { soldeCongesAnnuels: { increment: leave.nombreJours } },
          });
        } else if (leave.type === 'maladie') {
          await prisma.employee.update({
            where: { id: leave.employeeId },
            data: { soldeCongesMaladie: { increment: leave.nombreJours } },
          });
        }
      }
    }

    await prisma.leave.delete({ where: { id } });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'leaves',
        documentId: id,
        description: `Suppression congé`,
      },
    });

    res.json({ message: 'Congé supprimé avec succès' });
  } catch (error) {
    next(error);
  }
};

export const getPendingLeaves = async (req, res, next) => {
  try {
    const leaves = await prisma.leave.findMany({
      where: { statut: 'en_attente' },
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true, poste: true, departementNom: true } },
      },
      orderBy: { createdAt: 'asc' },
    });

    res.json({ leaves });
  } catch (error) {
    next(error);
  }
};