"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const router = (0, express_1.Router)();
// Mock Auth logic for M2 Alpha
router.post('/login', (req, res) => {
    // For now, regardless of what they send, return a static guest token or user info
    // M1 Adaptive Engine uses "ae30193e-83b3-c392-1192-9cad0e1f2031" for the mock user
    res.json({
        token: 'static-guest-token',
        user: {
            id: 'ae30193e-83b3-c392-1192-9cad0e1f2031',
            email: 'guest@arbormed.com',
            role: 'STUDENT',
            organizationId: 'med-uni-01'
        }
    });
});
exports.default = router;
