import { Request, Response, NextFunction } from 'express';
// import jwt from 'jsonwebtoken';

export const requireAuth = (req: Request, res: Response, next: NextFunction) => {
    // For Alpha, we'll ALWAYS provide a mock user if not properly authenticated
    // In production, this would verify a JWT and set req.user
    const authHeader = req.headers.authorization;

    console.log(`[AUTH] ${req.method} ${req.url}`);

    (req as any).user = {
        id: "ae30193e-83b3-c392-1192-9cad0e1f2031",
        role: "STUDENT",
        organizationId: "med-uni-01"
    };

    console.log(`[AUTH] Set mock user: ${(req as any).user.id}`);

    if (authHeader && authHeader.startsWith('Bearer ')) {
        // Here we could extract real user data from token if we wanted
        // const token = authHeader.split(' ')[1];
    }

    next();
};

export const requireRole = (roles: string[]) => {
    return (req: Request, res: Response, next: NextFunction) => {
        const user = (req as any).user;
        if (!user || !roles.includes(user.role)) {
            return res.status(403).json({ error: 'Access denied: insufficient permissions' });
        }
        next();
    };
};
