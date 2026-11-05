import { ZodError } from 'zod';
import { Prisma } from '@prisma/client';
import config from '../config/index.js';

export class AppError extends Error {
  constructor(message, statusCode = 500, code = 'INTERNAL_ERROR', details = null) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
  
}

export class ValidationError extends AppError {
  constructor(message, details) {
    super(message, 400, 'VALIDATION_ERROR', details);
  }
}

export class AuthenticationError extends AppError {
  constructor(message = 'Non authentifié') {
    super(message, 401, 'AUTHENTICATION_ERROR');
  }
}

export class AuthorizationError extends AppError {
  constructor(message = 'Non autorisé') {
    super(message, 403, 'AUTHORIZATION_ERROR');
  }
}

export class NotFoundError extends AppError {
  constructor(resource = 'Ressource') {
    super(`${resource} non trouvé`, 404, 'NOT_FOUND');
  }
}

export class ConflictError extends AppError {
  constructor(message) {
    super(message, 409, 'CONFLICT');
  }
}

export const notFoundHandler = (req, res, next) => {
  throw new NotFoundError(`Route ${req.method} ${req.path}`);
};

export const errorHandler = (err, req, res, next) => {
  console.error('Error:', {
    message: err.message,
    code: err.code,
    statusCode: err.statusCode,
    stack: err.stack,
    path: req.path,
    method: req.method,
  });

  // Zod validation errors
  if (err instanceof ZodError) {
    const details = err.errors.map(e => ({
      field: e.path.join('.'),
      message: e.message,
    }));
    return res.status(400).json({
      error: 'Erreur de validation',
      code: 'VALIDATION_ERROR',
      details,
    });
  }

  // Prisma errors
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === 'P2002') {
      const field = err.meta?.target?.[0] || 'champ';
      return res.status(409).json({
        error: `Ce ${field} existe déjà`,
        code: 'CONFLICT',
      });
    }
    if (err.code === 'P2025') {
      return res.status(404).json({
        error: 'Enregistrement non trouvé',
        code: 'NOT_FOUND',
      });
    }
    if (err.code === 'P2003') {
      return res.status(400).json({
        error: 'Référence invalide',
        code: 'INVALID_REFERENCE',
      });
    }
  }

  // Operational errors
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: err.message,
      code: err.code,
      details: err.details,
    });
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      error: 'Token invalide',
      code: 'INVALID_TOKEN',
    });
  }
  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({
      error: 'Token expiré',
      code: 'TOKEN_EXPIRED',
    });
  }

  // Default error
  return res.status(500).json({
    error: config.nodeEnv === 'development' ? err.message : 'Erreur interne du serveur',
    code: 'INTERNAL_ERROR',
  });
};