const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../db/database');
const { requireAuth, requireParent } = require('../middleware/auth');

const router = express.Router();

// Get current user profile
router.get('/me', requireAuth, (req, res) => {
  const user = db.prepare('SELECT id, username, name, role, avatar_emoji, points, created_at FROM users WHERE id = ?').get(req.user.id);
  if (!user) return res.status(404).json({ error: '用户不存在' });
  res.json(user);
});

// List all children (parent only)
router.get('/children', requireParent, (req, res) => {
  const children = db.prepare(
    "SELECT id, username, name, avatar_emoji, points, created_at FROM users WHERE role = 'child' ORDER BY name"
  ).all();
  res.json(children);
});

// Create child account (parent only)
router.post('/children', requireParent, (req, res) => {
  const { username, password, name, avatar_emoji } = req.body;
  if (!username || !password || !name) {
    return res.status(400).json({ error: '请填写用户名、密码和姓名' });
  }
  if (password.length < 4) {
    return res.status(400).json({ error: '密码至少需要4位' });
  }

  const existing = db.prepare('SELECT id FROM users WHERE username = ?').get(username);
  if (existing) return res.status(400).json({ error: '用户名已被使用' });

  const password_hash = bcrypt.hashSync(password, 10);
  const result = db.prepare(
    "INSERT INTO users (username, password_hash, name, role, avatar_emoji) VALUES (?, ?, ?, 'child', ?)"
  ).run(username, password_hash, name, avatar_emoji || '😊');

  const newUser = db.prepare('SELECT id, username, name, avatar_emoji, points FROM users WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json(newUser);
});

// Update user (parent only — can update any child; or self)
router.put('/:id', requireAuth, (req, res) => {
  const targetId = parseInt(req.params.id);
  const { name, password, avatar_emoji } = req.body;

  // Only parent can update others; child can only update themselves
  if (req.user.role !== 'parent' && req.user.id !== targetId) {
    return res.status(403).json({ error: '权限不足' });
  }

  const target = db.prepare('SELECT * FROM users WHERE id = ?').get(targetId);
  if (!target) return res.status(404).json({ error: '用户不存在' });

  // Parent cannot modify other parents
  if (req.user.role === 'parent' && target.role === 'parent' && target.id !== req.user.id) {
    return res.status(403).json({ error: '无法修改其他家长账号' });
  }

  const updates = {};
  if (name) updates.name = name;
  if (avatar_emoji) updates.avatar_emoji = avatar_emoji;
  if (password) {
    if (password.length < 4) return res.status(400).json({ error: '密码至少需要4位' });
    updates.password_hash = bcrypt.hashSync(password, 10);
  }

  if (Object.keys(updates).length === 0) {
    return res.status(400).json({ error: '没有要更新的内容' });
  }

  const setClauses = Object.keys(updates).map(k => `${k} = ?`).join(', ');
  db.prepare(`UPDATE users SET ${setClauses} WHERE id = ?`).run(...Object.values(updates), targetId);

  const updated = db.prepare('SELECT id, username, name, avatar_emoji, points FROM users WHERE id = ?').get(targetId);
  res.json(updated);
});

// Delete child account (parent only)
router.delete('/:id', requireParent, (req, res) => {
  const targetId = parseInt(req.params.id);
  const target = db.prepare('SELECT * FROM users WHERE id = ?').get(targetId);
  if (!target) return res.status(404).json({ error: '用户不存在' });
  if (target.role === 'parent') return res.status(400).json({ error: '无法删除家长账号' });

  db.prepare('DELETE FROM users WHERE id = ?').run(targetId);
  res.json({ message: '账号已删除' });
});

module.exports = router;
