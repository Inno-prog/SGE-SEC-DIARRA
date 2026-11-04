import bcrypt from 'bcryptjs';
import prisma from '../config/prisma.js';
import { generateTokens, verifyRefreshToken } from '../middleware/auth.js';
import {
  loginSchema,
  registerSchema,
  refreshTokenSchema,
  changePasswordSchema,
  resetPasswordSchema,
  updateProfileSchema,
} from '../utils/validation.js';
import { AppError, AuthenticationError, ValidationError, ConflictError } from '../middleware/errorHandler.js';

const hashPassword = async (password) => {
  return bcrypt.hash(password, 12);
};

const comparePassword = async (password, hash) => {
  return bcrypt.compare(password, hash);
};

export const login = async (req, res, next) => {
  try {
    const { email, password } = loginSchema.parse(req.body);

    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new AuthenticationError('Email ou mot de passe incorrect');
    }

    if (!user.isActive) {
      throw new AuthenticationError('Compte désactivé');
    }

    const isValid = await comparePassword(password, user.passwordHash);
    if (!isValid) {
      throw new AuthenticationError('Email ou mot de passe incorrect');
    }

    // Update last login
    await prisma.user.update({
      where: { id: user.id },
      data: { lastLogin: new Date() },
    });

    const { accessToken, refreshToken } = generateTokens(user);

    // Remove password hash from response
    const { passwordHash, ...userWithoutPassword } = user;

    res.json({
      user: userWithoutPassword,
      accessToken,
      refreshToken,
    });
  } catch (error) {
    next(error);
  }
};

export const register = async (req, res, next) => {
  try {
    const data = registerSchema.parse(req.body);

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
    });

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: user.id,
        userNom: `${user.prenom} ${user.nom}`,
        action: 'ajout',
        collection: 'users',
        documentId: user.id,
        description: `Création du compte utilisateur ${user.email}`,
      },
    });

    const { accessToken, refreshToken } = generateTokens(user);
    const { passwordHash: _, ...userWithoutPassword } = user;

    res.status(201).json({
      user: userWithoutPassword,
      accessToken,
      refreshToken,
    });
  } catch (error) {
    next(error);
  }
};

export const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = refreshTokenSchema.parse(req.body);

    let decoded;
    try {
      decoded = verifyRefreshToken(refreshToken);
    } catch (err) {
      throw new AuthenticationError('Refresh token invalide ou expiré');
    }

    if (decoded.type !== 'refresh') {
      throw new AuthenticationError('Token de type invalide');
    }

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        nom: true,
        prenom: true,
        role: true,
        employeeId: true,
        isActive: true,
        permissions: true,
      },
    });

    if (!user || !user.isActive) {
      throw new AuthenticationError('Utilisateur non trouvé ou inactif');
    }

    const { accessToken, refreshToken: newRefreshToken } = generateTokens(user);

    res.json({
      accessToken,
      refreshToken: newRefreshToken,
    });
  } catch (error) {
    next(error);
  }
};

export const logout = async (req, res, next) => {
  try {
    // In a stateless JWT system, logout is handled client-side
    // Optionally, you could maintain a blocklist of tokens in Redis
    res.json({ message: 'Déconnexion réussie' });
  } catch (error) {
    next(error);
  }
};

export const getProfile = async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
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
      throw new AppError('Utilisateur non trouvé', 404, 'NOT_FOUND');
    }

    // If user has employeeId, fetch employee details
    let employee = null;
    if (user.employeeId) {
      employee = await prisma.employee.findUnique({
        where: { id: user.employeeId },
        select: {
          id: true,
          matricule: true,
          poste: true,
          service: true,
          departementId: true,
          departementNom: true,
          grade: true,
          salaire: true,
          statut: true,
        },
      });
    }

    res.json({ user, employee });
  } catch (error) {
    next(error);
  }
};

export const updateProfile = async (req, res, next) => {
  try {
    const data = updateProfileSchema.parse(req.body);

    const user = await prisma.user.update({
      where: { id: req.user.id },
      data: {
        nom: data.nom,
        prenom: data.prenom,
        photoUrl: data.photoUrl,
        darkMode: data.darkMode,
        emailNotifications: data.emailNotifications,
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
        documentId: req.user.id,
        description: 'Mise à jour du profil utilisateur',
      },
    });

    res.json({ user });
  } catch (error) {
    next(error);
  }
};

export const changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = changePasswordSchema.parse(req.body);

    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
    });

    const isValid = await comparePassword(currentPassword, user.passwordHash);
    if (!isValid) {
      throw new AuthenticationError('Mot de passe actuel incorrect');
    }

    const passwordHash = await hashPassword(newPassword);

    await prisma.user.update({
      where: { id: req.user.id },
      data: {
        passwordHash,
        mustChangePassword: false,
      },
    });

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'modification',
        collection: 'users',
        documentId: req.user.id,
        description: 'Changement de mot de passe',
      },
    });

    res.json({ message: 'Mot de passe modifié avec succès' });
  } catch (error) {
    next(error);
  }
};

export const requestPasswordReset = async (req, res, next) => {
  try {
    const { email } = resetPasswordSchema.parse(req.body);

    const user = await prisma.user.findUnique({
      where: { email },
    });

    // Always return success to prevent email enumeration
    if (!user) {
      return res.json({ message: 'Si cet email existe, un lien de réinitialisation a été envoyé' });
    }

    // TODO: Implement email sending with reset token
    // For now, just log the request
    console.log(`Password reset requested for: ${email}`);

    // Create audit log
    await prisma.auditLog.create({
      data: {
        userId: user.id,
        userNom: `${user.prenom} ${user.nom}`,
        action: 'modification',
        collection: 'users',
        documentId: user.id,
        description: 'Demande de réinitialisation de mot de passe',
      },
    });

    res.json({ message: 'Si cet email existe, un lien de réinitialisation a été envoyé' });
  } catch (error) {
    next(error);
  }
};

export const verifyAuth = async (req, res, next) => {
  try {
    // This endpoint just verifies the token is valid
    // The auth middleware already validated the user
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        email: true,
        nom: true,
        prenom: true,
        role: true,
        employeeId: true,
        isActive: true,
        permissions: true,
      },
    });

    if (!user || !user.isActive) {
      throw new AuthenticationError('Utilisateur non trouvé ou inactif');
    }

    res.json({ user, valid: true });
  } catch (error) {
    next(error);
  }
};