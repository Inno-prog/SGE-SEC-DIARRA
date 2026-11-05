import prisma from '../config/prisma.js';
import { AppError, NotFoundError, ConflictError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createUserSchema,
  updateUserSchema,
  paginationSchema,
  updateUserStatusSchema,
} from '../utils/validation.js';
import bcrypt from 'bcryptjs';

const hashPassword = async (password) => {
  return bcrypt.hash(password, 12);
};

export const getUsers = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, ...filters } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (filters.role) where.role = filters.role;
    if (filters.isActive !== undefined) where.isActive = filters.isActive === 'true';
    if (filters.search) {
      where.OR = [
        { email: { contains: filters.search, mode: 'insensitive' } },
        { nom: { contains: filters.search, mode: 'insensitive' } },
        { prenom: { contains: filters.search, mode: 'insensitive' } },
      ];
    }

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { createdAt: 'desc' },
        select: {
          id: true,
          email: true,
          nom: true,
          prenom: true,
          role: true,
          employeeId: true,
          photoUrl: true,
          isActive: true,
          twoFactorEnabled: true,
          createdAt: true,
          lastLogin: true,
          permissions: true,
          darkMode: true,
          emailNotifications: true,
          mustChangePassword: true,
        },
      }),
      prisma.user.count({ where }),
    ]);

    res.json({
      data: users,
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

export const getUserById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        email: true,
        nom: true,
        prenom: true,
        role: true,
        employeeId: true,
        photoUrl: true,
        isActive: true,
        twoFactorEnabled: true,
        createdAt: true,
        lastLogin: true,
        permissions: true,
        darkMode: true,
        emailNotifications: true,
        mustChangePassword: true,
      },
    });

    if (!user) {
      throw new NotFoundError('Utilisateur');
    }

    res.json({ user });
  } catch (error) {
    next(error);
  }
};

export const createUser = async (req, res, next) => {
  try {
    const data = createUserSchema.parse(req.body);

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: data.email },
    });

    if (existingUser) {
      throw new ConflictError('Cet email est déjà utilisé');
    }

    // Check if employeeId exists (if provided)
    if (data.employeeId) {
      const existingEmployee = await prisma.user.findUnique({
        where: { employeeId: data.employeeId },
      });
      if (existingEmployee) {
        throw new ConflictError('Cet employé est déjà associé à un compte');
      }
    }

    const passwordHash = await hashPassword(data.password);

    const user = await prisma.user.create({
      data: {
        email: data.email,
        passwordHash,
        nom: data.nom,
        prenom: data.prenom,
        role: data.role,
        employeeId: data.employeeId,
        permissions: data.permissions || [],
      },
      select: {
        id: true,
        email: true,
        nom: true,
        prenom: true,
        role: true,
        employeeId: true,
        photoUrl: true,
        isActive: true,
        twoFactorEnabled: true,
        createdAt: true,
        lastLogin: true,
        permissions: true,
        darkMode: true,
        emailNotifications: true,
        mustChangePassword: true,
      },
    });

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'ajout',
        collection: 'users',
        documentId: user.id,
        description: `Création de l'utilisateur ${user.email}`,
      },
    });

    res.status(201).json({ user });
  } catch (error) {
    next(error);
  }
};

export const updateUser = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateUserSchema.parse(req.body);

    // Check if user exists
    const existingUser = await prisma.user.findUnique({ where: { id } });
    if (!existingUser) {
      throw new NotFoundError('Utilisateur');
    }

    // Check email uniqueness if changing
    if (data.email && data.email !== existingUser.email) {
      const emailExists = await prisma.user.findUnique({
        where: { email: data.email },
      });
      if (emailExists) {
        throw new ConflictError('Cet email est déjà utilisé');
      }
    }

    // Check employeeId uniqueness if changing
    if (data.employeeId && data.employeeId !== existingUser.employeeId) {
      const employeeExists = await prisma.user.findUnique({
        where: { employeeId: data.employeeId },
      });
      if (employeeExists) {
        throw new ConflictError('Cet employé est déjà associé à un compte');
      }
    }

    const user = await prisma.user.update({
      where: { id },
      data: {
        nom: data.nom,
        prenom: data.prenom,
        role: data.role,
        employeeId: data.employeeId,
        isActive: data.isActive,
        permissions: data.permissions,
        darkMode: data.darkMode,
        emailNotifications: data.emailNotifications,
        mustChangePassword: data.mustChangePassword,
      },
      select: {
        id: true,
        email: true,
        nom: true,
        prenom: true,
        role: true,
        employeeId: true,
        photoUrl: true,
        isActive: true,
        twoFactorEnabled: true,
        createdAt: true,
        lastLogin: true,
        permissions: true,
        darkMode: true,
        emailNotifications: true,
        mustChangePassword: true,
      },
    });

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'modification',
        collection: 'users',
        documentId: user.id,
        description: `Mise à jour de l'utilisateur ${user.email}`,
      },
    });

    res.json({ user });
  } catch (error) {
    next(error);
  }
};

export const updateUserStatus = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const { isActive } = updateUserStatusSchema.parse(req.body);

    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) {
      throw new NotFoundError('Utilisateur');
    }

    const updatedUser = await prisma.user.update({
      where: { id },
      data: { isActive },
      select: {
        id: true,
        email: true,
        nom: true,
        prenom: true,
        role: true,
        employeeId: true,
        photoUrl: true,
        isActive: true,
        twoFactorEnabled: true,
        createdAt: true,
        lastLogin: true,
        permissions: true,
        darkMode: true,
        emailNotifications: true,
        mustChangePassword: true,
      },
    });

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'modification',
        collection: 'users',
        documentId: user.id,
        description: `Changement de statut de l'utilisateur ${user.email} (${isActive ? 'activé' : 'désactivé'})`,
      },
    });

    res.json({ user: updatedUser });
  } catch (error) {
    next(error);
  }
};

export const deleteUser = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    // Prevent self-deletion
    if (id === req.user.id) {
      throw new AppError('Vous ne pouvez pas supprimer votre propre compte', 400, 'SELF_DELETE');
    }

    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) {
      throw new NotFoundError('Utilisateur');
    }

    await prisma.user.delete({ where: { id } });

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'users',
        documentId: id,
        description: `Suppression de l'utilisateur ${user.email}`,
      },
    });

    res.json({ message: 'Utilisateur supprimé avec succès' });
  } catch (error) {
    next(error);
  }
};

export const resetUserPassword = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const { newPassword } = req.body;

    if (!newPassword || newPassword.length < 6) {
      throw new AppError('Le nouveau mot de passe doit contenir au moins 6 caractères', 400, 'VALIDATION_ERROR');
    }

    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) {
      throw new NotFoundError('Utilisateur');
    }

    const passwordHash = await hashPassword(newPassword);

    await prisma.user.update({
      where: { id },
      data: {
        passwordHash,
        mustChangePassword: true,
      },
    });

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'modification',
        collection: 'users',
        documentId: id,
        description: `Réinitialisation du mot de passe pour ${user.email}`,
      },
    });

    res.json({ message: 'Mot de passe réinitialisé avec succès' });
  } catch (error) {
    next(error);
  }
};