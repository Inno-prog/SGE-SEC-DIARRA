import prisma from '../config/prisma.js';
import { AppError, NotFoundError, ConflictError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createEmployeeSchema,
  updateEmployeeSchema,
  employeeQuerySchema,
} from '../utils/validation.js';

export const getEmployees = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, departementId, statut, search } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (departementId) where.departementId = departementId;
    if (statut) where.statut = statut;
    if (search) {
      where.OR = [
        { nom: { contains: search, mode: 'insensitive' } },
        { prenom: { contains: search, mode: 'insensitive' } },
        { matricule: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
        { departementNom: { contains: search, mode: 'insensitive' } },
        { poste: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [employees, total] = await Promise.all([
      prisma.employee.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { nom: 'asc' },
        include: {
          departement: { select: { id: true, nom: true } },
        },
      }),
      prisma.employee.count({ where }),
    ]);

    res.json({
      data: employees,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    next(error);
  }
};

export const getEmployeeById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const employee = await prisma.employee.findUnique({
      where: { id },
      include: {
        departement: { select: { id: true, nom: true, description: true } },
        user: { select: { id: true, email: true, role: true, isActive: true } },
        contracts: { orderBy: { dateDebut: 'desc' }, take: 5 },
        attendances: { orderBy: { date: 'desc' }, take: 10 },
        leaves: { orderBy: { dateDebut: 'desc' }, take: 5 },
        payrolls: { orderBy: { createdAt: 'desc' }, take: 5 },
        documents: { orderBy: { createdAt: 'desc' }, take: 5 },
      },
    });

    if (!employee) {
      throw new NotFoundError('Employé');
    }

    res.json({ employee });
  } catch (error) {
    next(error);
  }
};

export const createEmployee = async (req, res, next) => {
  try {
    const data = createEmployeeSchema.parse(req.body);

    // Check if matricule already exists
    const existingMatricule = await prisma.employee.findUnique({
      where: { matricule: data.matricule },
    });
    if (existingMatricule) {
      throw new ConflictError('Ce matricule existe déjà');
    }

    // Check if email already exists
    const existingEmail = await prisma.employee.findUnique({
      where: { email: data.email },
    });
    if (existingEmail) {
      throw new ConflictError('Cet email est déjà utilisé');
    }

    // Verify department exists
    const department = await prisma.department.findUnique({
      where: { id: data.departementId },
    });
    if (!department) {
      throw new NotFoundError('Département');
    }

    const employee = await prisma.employee.create({
      data: {
        ...data,
        dateNaissance: new Date(data.dateNaissance),
        dateEmbauche: new Date(data.dateEmbauche),
        createdBy: req.user.id,
      },
      include: {
        departement: { select: { id: true, nom: true } },
      },
    });

    // Update department employee count
    await prisma.department.update({
      where: { id: data.departementId },
      data: { nombreEmployes: { increment: 1 } },
    });

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'ajout',
        collection: 'employees',
        documentId: employee.id,
        description: `Création de l'employé ${employee.matricule} - ${employee.prenom} ${employee.nom}`,
      },
    });

    res.status(201).json({ employee });
  } catch (error) {
    next(error);
  }
};

export const updateEmployee = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateEmployeeSchema.parse(req.body);

    const existingEmployee = await prisma.employee.findUnique({ where: { id } });
    if (!existingEmployee) {
      throw new NotFoundError('Employé');
    }

    // Check email uniqueness if changing
    if (data.email && data.email !== existingEmployee.email) {
      const emailExists = await prisma.employee.findUnique({
        where: { email: data.email },
      });
      if (emailExists) {
        throw new ConflictError('Cet email est déjà utilisé');
      }
    }

    // Verify department if changing
    if (data.departementId && data.departementId !== existingEmployee.departementId) {
      const department = await prisma.department.findUnique({
        where: { id: data.departementId },
      });
      if (!department) {
        throw new NotFoundError('Département');
      }
    }

    const updateData = { ...data };
    if (data.dateNaissance) updateData.dateNaissance = new Date(data.dateNaissance);
    if (data.dateEmbauche) updateData.dateEmbauche = new Date(data.dateEmbauche);
    updateData.updatedBy = req.user.id;

    const employee = await prisma.employee.update({
      where: { id },
      data: updateData,
      include: {
        departement: { select: { id: true, nom: true } },
      },
    });

    // Update department counts if department changed
    if (data.departementId && data.departementId !== existingEmployee.departementId) {
      await prisma.department.update({
        where: { id: existingEmployee.departementId },
        data: { nombreEmployes: { decrement: 1 } },
      });
      await prisma.department.update({
        where: { id: data.departementId },
        data: { nombreEmployes: { increment: 1 } },
      });
    }

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'modification',
        collection: 'employees',
        documentId: employee.id,
        description: `Mise à jour de l'employé ${employee.matricule} - ${employee.prenom} ${employee.nom}`,
      },
    });

    res.json({ employee });
  } catch (error) {
    next(error);
  }
};

export const deleteEmployee = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const employee = await prisma.employee.findUnique({ where: { id } });
    if (!employee) {
      throw new NotFoundError('Employé');
    }

    await prisma.employee.delete({ where: { id } });

    // Update department employee count
    await prisma.department.update({
      where: { id: employee.departementId },
      data: { nombreEmployes: { decrement: 1 } },
    });

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'employees',
        documentId: id,
        description: `Suppression de l'employé ${employee.matricule} - ${employee.prenom} ${employee.nom}`,
      },
    });

    res.json({ message: 'Employé supprimé avec succès' });
  } catch (error) {
    next(error);
  }
};

export const generateMatricule = async (req, res, next) => {
  try {
    const lastEmployee = await prisma.employee.findFirst({
      orderBy: { matricule: 'desc' },
      select: { matricule: true },
    });

    let nextNum = 1;
    if (lastEmployee?.matricule) {
      const match = lastEmployee.matricule.match(/EMP(\d+)/);
      if (match) {
        nextNum = parseInt(match[1], 10) + 1;
      }
    }

    const matricule = `EMP${nextNum.toString().padStart(4, '0')}`;
    res.json({ matricule });
  } catch (error) {
    next(error);
  }
};

export const getEmployeeStats = async (req, res, next) => {
  try {
    const [
      total,
      actifs,
      enConge,
      suspendus,
      byDepartment,
      byStatut,
    ] = await Promise.all([
      prisma.employee.count(),
      prisma.employee.count({ where: { statut: 'actif' } }),
      prisma.employee.count({ where: { statut: 'conge' } }),
      prisma.employee.count({ where: { statut: 'suspendu' } }),
      prisma.employee.groupBy({
        by: ['departementId'],
        _count: true,
      }),
      prisma.employee.groupBy({
        by: ['statut'],
        _count: true,
      }),
    ]);

    // Get department names
    const deptIds = byDepartment.map(d => d.departementId);
    const departments = await prisma.department.findMany({
      where: { id: { in: deptIds } },
      select: { id: true, nom: true },
    });
    const deptMap = Object.fromEntries(departments.map(d => [d.id, d.nom]));

    res.json({
      total,
      actifs,
      enConge,
      suspendus,
      byDepartment: byDepartment.map(d => ({
        departementId: d.departementId,
        departementNom: deptMap[d.departementId] || 'Inconnu',
        count: d._count,
      })),
      byStatut: byStatut.map(s => ({ statut: s.statut, count: s._count })),
    });
  } catch (error) {
    next(error);
  }
};

export const getBirthdaysThisMonth = async (req, res, next) => {
  try {
    const now = new Date();
    const month = now.getMonth() + 1;

    const employees = await prisma.employee.findMany({
      where: {
        // Use raw query for month extraction since Prisma doesn't support month() directly
      },
      select: {
        id: true,
        matricule: true,
        nom: true,
        prenom: true,
        dateNaissance: true,
        poste: true,
        departementNom: true,
      },
    });

    // Filter by month in JS (could be optimized with raw query)
    const birthdays = employees.filter(e => e.dateNaissance.getMonth() + 1 === month);

    res.json({ birthdays });
  } catch (error) {
    next(error);
  }
};