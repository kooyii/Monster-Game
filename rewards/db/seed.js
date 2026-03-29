const bcrypt = require('bcryptjs');
const db = require('./database');

function seed() {
  const existingUsers = db.prepare('SELECT COUNT(*) as count FROM users').get();
  if (existingUsers.count > 0) return;

  console.log('Seeding database with initial data...');

  // Create default parent account
  const passwordHash = bcrypt.hashSync('family2024', 10);
  db.prepare(`
    INSERT INTO users (username, password_hash, name, role, avatar_emoji)
    VALUES (?, ?, ?, 'parent', '👨‍👩‍👧‍👦')
  `).run('admin', passwordHash, '爸爸妈妈');

  // Create sample rewards
  const insertReward = db.prepare(`
    INSERT INTO rewards (name, description, points_cost, emoji)
    VALUES (?, ?, ?, ?)
  `);

  const rewards = [
    ['看电影', '去电影院看一场喜欢的电影', 50, '🎬'],
    ['看球赛', '去现场观看一场精彩的球赛', 100, '⚽'],
    ['打台球', '去台球厅打一小时台球', 60, '🎱'],
    ['豪华晚餐', '去喜欢的餐厅吃一顿大餐', 80, '🍜'],
    ['神秘礼物', '爸爸妈妈为你准备的惊喜礼物', 120, '🎁'],
    ['游戏时间', '额外获得1小时游戏时间', 30, '🎮'],
    ['买玩具', '去选购一个心仪的玩具', 150, '🧸'],
    ['冰淇淋日', '去吃喜欢的冰淇淋', 20, '🍦'],
  ];

  rewards.forEach(([name, description, points_cost, emoji]) => {
    insertReward.run(name, description, points_cost, emoji);
  });

  console.log('Seed complete! Default login: admin / family2024');
}

module.exports = seed;
