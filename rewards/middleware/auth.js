const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'family-rewards-secret-2024';

function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: '请先登录' });
  }
  const token = authHeader.slice(7);
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: '登录已过期，请重新登录' });
  }
}

function requireParent(req, res, next) {
  requireAuth(req, res, () => {
    if (req.user.role !== 'parent') {
      return res.status(403).json({ error: '权限不足' });
    }
    next();
  });
}

module.exports = { requireAuth, requireParent, JWT_SECRET };
