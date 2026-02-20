import { Request, Response, NextFunction } from 'express';
// import jwt from 'jsonwebtoken';

export const requireAuth = (req: Request, res: Response, next: NextFunction) => {
    // For Alpha, we'll mock a user if no header is present
    // In production, this would verify a JWT
    const authHeader = req.headers.authorization;

    if (!authHeader) {
        // Mock user for testing
        (req as any).user = {
            id: "ae30193e-83b3-c392-1192-9cad0e1f2031",
            role: "STUDENT",
            organizationId: "med-uni-01"
        };
        return next();
    }

    // Real JWT logic would go here
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
