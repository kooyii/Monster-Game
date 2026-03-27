// Public read-only endpoints — no authentication required
// Used by the Android app's child view (tap-to-view, no login)
const express = require('express');
const db = require('../db/database');

const router = express.Router();

// GET /api/public/children — all children with current points
router.get('/children', (req, res) => {
  const children = db.prepare(
    "SELECT id, name, avatar_emoji, points FROM users WHERE role = 'child' ORDER BY points DESC"
  ).all();
  res.json(children);
});

// GET /api/public/children/:id — single child's profile + recent transactions
router.get('/children/:id', (req, res) => {
  const child = db.prepare(
    "SELECT id, name, avatar_emoji, points FROM users WHERE id = ? AND role = 'child'"
  ).get(req.params.id);
  if (!child) return res.status(404).json({ error: '找不到该孩子' });

  const transactions = db.prepare(`
    SELECT points, description, type, created_at
    FROM point_transactions
    WHERE child_id = ?
    ORDER BY created_at DESC
    LIMIT 20
  `).all(req.params.id);

  res.json({ ...child, transactions });
});

// GET /api/public/rewards — active rewards list (for child to see what they can earn towards)
router.get('/rewards', (req, res) => {
  const rewards = db.prepare(
    'SELECT id, name, description, points_cost, emoji FROM rewards WHERE is_active = 1 ORDER BY points_cost ASC'
  ).all();
  res.json(rewards);
});

module.exports = router;
