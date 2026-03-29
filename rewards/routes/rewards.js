const express = require('express');
const db = require('../db/database');
const { requireAuth, requireParent } = require('../middleware/auth');

const router = express.Router();

// List active rewards
router.get('/', requireAuth, (req, res) => {
  const includeInactive = req.user.role === 'parent' && req.query.all === '1';
  const rewards = db.prepare(
    includeInactive
      ? 'SELECT * FROM rewards ORDER BY points_cost ASC'
      : 'SELECT * FROM rewards WHERE is_active = 1 ORDER BY points_cost ASC'
  ).all();
  res.json(rewards);
});

// Create reward (parent only)
router.post('/', requireParent, (req, res) => {
  const { name, description, points_cost, emoji } = req.body;
  if (!name || !points_cost) {
    return res.status(400).json({ error: '请填写奖励名称和所需积分' });
  }
  const cost = parseInt(points_cost);
  if (isNaN(cost) || cost <= 0) {
    return res.status(400).json({ error: '积分必须是正整数' });
  }

  const result = db.prepare(
    'INSERT INTO rewards (name, description, points_cost, emoji) VALUES (?, ?, ?, ?)'
  ).run(name, description || '', cost, emoji || '🎁');

  const reward = db.prepare('SELECT * FROM rewards WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json(reward);
});

// Update reward (parent only)
router.put('/:id', requireParent, (req, res) => {
  const reward = db.prepare('SELECT * FROM rewards WHERE id = ?').get(req.params.id);
  if (!reward) return res.status(404).json({ error: '奖励不存在' });

  const { name, description, points_cost, emoji, is_active } = req.body;
  const updates = {};
  if (name !== undefined) updates.name = name;
  if (description !== undefined) updates.description = description;
  if (points_cost !== undefined) {
    const cost = parseInt(points_cost);
    if (isNaN(cost) || cost <= 0) return res.status(400).json({ error: '积分必须是正整数' });
    updates.points_cost = cost;
  }
  if (emoji !== undefined) updates.emoji = emoji;
  if (is_active !== undefined) updates.is_active = is_active ? 1 : 0;

  if (Object.keys(updates).length === 0) {
    return res.status(400).json({ error: '没有要更新的内容' });
  }

  const setClauses = Object.keys(updates).map(k => `${k} = ?`).join(', ');
  db.prepare(`UPDATE rewards SET ${setClauses} WHERE id = ?`).run(...Object.values(updates), req.params.id);

  const updated = db.prepare('SELECT * FROM rewards WHERE id = ?').get(req.params.id);
  res.json(updated);
});

// Soft-delete reward (parent only)
router.delete('/:id', requireParent, (req, res) => {
  const reward = db.prepare('SELECT * FROM rewards WHERE id = ?').get(req.params.id);
  if (!reward) return res.status(404).json({ error: '奖励不存在' });

  db.prepare('UPDATE rewards SET is_active = 0 WHERE id = ?').run(req.params.id);
  res.json({ message: '奖励已停用' });
});

module.exports = router;
