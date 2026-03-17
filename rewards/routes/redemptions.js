const express = require('express');
const db = require('../db/database');
const { requireAuth, requireParent } = require('../middleware/auth');

const router = express.Router();

// Get redemption requests
router.get('/', requireAuth, (req, res) => {
  const { status, child_id } = req.query;
  let where = [];
  let params = [];

  if (req.user.role === 'child') {
    where.push('rr.child_id = ?');
    params.push(req.user.id);
  } else if (child_id) {
    where.push('rr.child_id = ?');
    params.push(child_id);
  }

  if (status) {
    where.push('rr.status = ?');
    params.push(status);
  }

  const whereClause = where.length ? 'WHERE ' + where.join(' AND ') : '';
  const requests = db.prepare(`
    SELECT rr.*, u.name as child_name, u.avatar_emoji, r.name as reward_name, r.emoji as reward_emoji, r.points_cost
    FROM redemption_requests rr
    JOIN users u ON u.id = rr.child_id
    JOIN rewards r ON r.id = rr.reward_id
    ${whereClause}
    ORDER BY rr.created_at DESC
  `).all(...params);

  res.json(requests);
});

// Create redemption request (child only)
router.post('/', requireAuth, (req, res) => {
  if (req.user.role !== 'child') {
    return res.status(403).json({ error: '只有孩子账号可以申请兑换' });
  }

  const { reward_id } = req.body;
  if (!reward_id) return res.status(400).json({ error: '请选择要兑换的奖励' });

  const reward = db.prepare('SELECT * FROM rewards WHERE id = ? AND is_active = 1').get(reward_id);
  if (!reward) return res.status(404).json({ error: '奖励不存在或已停用' });

  const child = db.prepare('SELECT points FROM users WHERE id = ?').get(req.user.id);
  if (child.points < reward.points_cost) {
    return res.status(400).json({ error: `积分不足，需要 ${reward.points_cost} 积分，当前 ${child.points} 积分` });
  }

  // Check for pending request for same reward
  const pending = db.prepare(
    "SELECT id FROM redemption_requests WHERE child_id = ? AND reward_id = ? AND status = 'pending'"
  ).get(req.user.id, reward_id);
  if (pending) return res.status(400).json({ error: '你已经有一个待审核的相同奖励申请' });

  const result = db.prepare(
    'INSERT INTO redemption_requests (child_id, reward_id) VALUES (?, ?)'
  ).run(req.user.id, reward_id);

  const request = db.prepare(`
    SELECT rr.*, r.name as reward_name, r.emoji as reward_emoji, r.points_cost
    FROM redemption_requests rr
    JOIN rewards r ON r.id = rr.reward_id
    WHERE rr.id = ?
  `).get(result.lastInsertRowid);

  res.status(201).json(request);
});

// Approve or reject redemption request (parent only)
router.put('/:id', requireParent, (req, res) => {
  const { status, notes } = req.body;
  if (!['approved', 'rejected'].includes(status)) {
    return res.status(400).json({ error: '状态必须是 approved 或 rejected' });
  }

  const request = db.prepare(`
    SELECT rr.*, r.points_cost, u.points as child_points
    FROM redemption_requests rr
    JOIN rewards r ON r.id = rr.reward_id
    JOIN users u ON u.id = rr.child_id
    WHERE rr.id = ?
  `).get(req.params.id);

  if (!request) return res.status(404).json({ error: '申请不存在' });
  if (request.status !== 'pending') return res.status(400).json({ error: '该申请已处理' });

  if (status === 'approved') {
    if (request.child_points < request.points_cost) {
      return res.status(400).json({ error: '孩子积分不足，无法批准' });
    }

    // Atomically approve: deduct points + create transaction + update request
    const approve = db.transaction(() => {
      db.prepare('UPDATE users SET points = points - ? WHERE id = ?').run(request.points_cost, request.child_id);
      db.prepare(
        "INSERT INTO point_transactions (child_id, awarded_by, points, description, type) VALUES (?, ?, ?, ?, 'redeem')"
      ).run(request.child_id, req.user.id, -request.points_cost, `兑换奖励: ${request.reward_id}`);
      db.prepare(
        'UPDATE redemption_requests SET status = ?, notes = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?'
      ).run(status, notes || null, req.params.id);
    });
    approve();
  } else {
    db.prepare(
      'UPDATE redemption_requests SET status = ?, notes = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?'
    ).run(status, notes || null, req.params.id);
  }

  const updated = db.prepare(`
    SELECT rr.*, u.name as child_name, r.name as reward_name, r.emoji as reward_emoji, r.points_cost
    FROM redemption_requests rr
    JOIN users u ON u.id = rr.child_id
    JOIN rewards r ON r.id = rr.reward_id
    WHERE rr.id = ?
  `).get(req.params.id);

  res.json(updated);
});

module.exports = router;
