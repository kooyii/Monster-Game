const express = require('express');
const db = require('../db/database');
const { requireAuth, requireParent } = require('../middleware/auth');

const router = express.Router();

// Award points to a child (parent only)
router.post('/award', requireParent, (req, res) => {
  const { child_id, points, description } = req.body;
  if (!child_id || !points || !description) {
    return res.status(400).json({ error: '请填写孩子、积分数量和原因' });
  }
  const pts = parseInt(points);
  if (isNaN(pts) || pts === 0) {
    return res.status(400).json({ error: '积分必须是非零整数' });
  }

  const child = db.prepare("SELECT id FROM users WHERE id = ? AND role = 'child'").get(child_id);
  if (!child) return res.status(404).json({ error: '孩子账号不存在' });

  // Use transaction to update balance atomically
  const award = db.transaction(() => {
    db.prepare(
      "INSERT INTO point_transactions (child_id, awarded_by, points, description, type) VALUES (?, ?, ?, ?, ?)"
    ).run(child_id, req.user.id, pts, description, pts > 0 ? 'earn' : 'redeem');

    db.prepare('UPDATE users SET points = points + ? WHERE id = ?').run(pts, child_id);

    return db.prepare('SELECT points FROM users WHERE id = ?').get(child_id);
  });

  const result = award();
  res.json({ message: '积分已更新', new_balance: result.points });
});

// Get transaction history
router.get('/transactions', requireAuth, (req, res) => {
  const { child_id, limit = 50, offset = 0 } = req.query;
  let query, params;

  if (req.user.role === 'parent') {
    if (child_id) {
      query = `
        SELECT pt.*, u.name as child_name, u.avatar_emoji, p.name as awarded_by_name
        FROM point_transactions pt
        JOIN users u ON u.id = pt.child_id
        LEFT JOIN users p ON p.id = pt.awarded_by
        WHERE pt.child_id = ?
        ORDER BY pt.created_at DESC LIMIT ? OFFSET ?
      `;
      params = [child_id, parseInt(limit), parseInt(offset)];
    } else {
      query = `
        SELECT pt.*, u.name as child_name, u.avatar_emoji, p.name as awarded_by_name
        FROM point_transactions pt
        JOIN users u ON u.id = pt.child_id
        LEFT JOIN users p ON p.id = pt.awarded_by
        ORDER BY pt.created_at DESC LIMIT ? OFFSET ?
      `;
      params = [parseInt(limit), parseInt(offset)];
    }
  } else {
    // Child can only see their own transactions
    query = `
      SELECT pt.*, u.name as child_name, u.avatar_emoji, p.name as awarded_by_name
      FROM point_transactions pt
      JOIN users u ON u.id = pt.child_id
      LEFT JOIN users p ON p.id = pt.awarded_by
      WHERE pt.child_id = ?
      ORDER BY pt.created_at DESC LIMIT ? OFFSET ?
    `;
    params = [req.user.id, parseInt(limit), parseInt(offset)];
  }

  const transactions = db.prepare(query).all(...params);
  res.json(transactions);
});

module.exports = router;
