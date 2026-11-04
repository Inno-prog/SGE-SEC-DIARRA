import prisma from '../config/prisma.js';
import { AppError, NotFoundError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createAttendanceSchema,
  updateAttendanceSchema,
  attendanceQuerySchema,
} from '../utils/validation.js';

export const getAttendances = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, employeeId, date, dateDebut, dateFin } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (employeeId) where.employeeId = employeeId;
    if (date) {
      const d = new Date(date);
      const nextDay = new Date(d);
      nextDay.setDate(d.getDate() + 1);
      where.date = { gte: d, lt: nextDay };
    } else if (dateDebut || dateFin) {
      where.date = {};
      if (dateDebut) where.date.gte = new Date(dateDebut);
      if (dateFin) where.date.lte = new Date(dateFin);
    }

    const [attendances, total] = await Promise.all([
      prisma.attendance.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { date: 'desc' },
        include: {
          employee: { select: { id: true, matricule: true, nom: true, prenom: true } },
          creator: { select: { id: true, nom: true, prenom: true } },
        },
      }),
      prisma.attendance.count({ where }),
    ]);

    res.json({
      data: attendances,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const getAttendanceById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const attendance = await prisma.attendance.findUnique({
      where: { id },
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true, email: true } },
        creator: { select: { id: true, nom: true, prenom: true, email: true } },
      },
    });

    if (!attendance) {
      throw new NotFoundError('Présence');
    }

    res.json({ attendance });
  } catch (error) {
    next(error);
  }
};

export const createAttendance = async (req, res, next) => {
  try {
    const data = createAttendanceSchema.parse(req.body);

    const employee = await prisma.employee.findUnique({ where: { id: data.employeeId } });
    if (!employee) {
      throw new NotFoundError('Employé');
    }

    // Check if attendance already exists for this employee on this date
    const existing = await prisma.attendance.findFirst({
      where: {
        employeeId: data.employeeId,
        date: new Date(data.date),
      },
    });
    if (existing) {
      throw new AppError('Une présence existe déjà pour cet employé à cette date', 409, 'DUPLICATE_ATTENDANCE');
    }

    const attendance = await prisma.attendance.create({
      data: {
        ...data,
        date: new Date(data.date),
        heureArrivee: data.heureArrivee ? new Date(data.heureArrivee) : null,
        heureDepart: data.heureDepart ? new Date(data.heureDepart) : null,
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
        collection: 'attendances',
        documentId: attendance.id,
        description: `Enregistrement présence pour ${employee.prenom} ${employee.nom}`,
      },
    });

    res.status(201).json({ attendance });
  } catch (error) {
    next(error);
  }
};

export const updateAttendance = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateAttendanceSchema.parse(req.body);

    const existing = await prisma.attendance.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Présence');
    }

    const updateData = { ...data };
    if (data.heureArrivee) updateData.heureArrivee = new Date(data.heureArrivee);
    if (data.heureDepart) updateData.heureDepart = new Date(data.heureDepart);

    const attendance = await prisma.attendance.update({
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
        collection: 'attendances',
        documentId: attendance.id,
        description: `Mise à jour présence pour ${attendance.employee.prenom} ${attendance.employee.nom}`,
      },
    });

    res.json({ attendance });
  } catch (error) {
    next(error);
  }
};

export const deleteAttendance = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const attendance = await prisma.attendance.findUnique({ where: { id } });
    if (!attendance) {
      throw new NotFoundError('Présence');
    }

    await prisma.attendance.delete({ where: { id } });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'attendances',
        documentId: id,
        description: `Suppression présence`,
      },
    });

    res.json({ message: 'Présence supprimée avec succès' });
  } catch (error) {
    next(error);
  }
};

export const getTodayAttendances = async (req, res, next) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const attendances = await prisma.attendance.findMany({
      where: { date: { gte: today, lt: tomorrow } },
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true, poste: true, departementNom: true } },
      },
      orderBy: { heureArrivee: 'asc' },
    });

    const stats = {
      present: attendances.filter(a => a.statut === 'present').length,
      absent: attendances.filter(a => a.statut === 'absent').length,
      retard: attendances.filter(a => a.statut === 'retard').length,
      conge: attendances.filter(a => a.statut === 'conge').length,
      mission: attendances.filter(a => a.statut === 'mission').length,
      total: attendances.length,
    };

    res.json({ attendances, stats });
  } catch (error) {
    next(error);
  }
};