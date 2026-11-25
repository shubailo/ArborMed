function isSuperAdmin(user) {
    if (user?.role !== 'admin') return false;
    const id = process.env.SUPER_ADMIN_USER_ID?.trim();
    if (id) return String(user.id) === id;
    const email = process.env.SUPER_ADMIN_EMAIL?.trim();
    return Boolean(email && user.email === email);
}

module.exports = { isSuperAdmin };
