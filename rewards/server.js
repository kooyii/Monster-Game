const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Initialize database and seed
require('./db/database');
require('./db/seed')();

// Serve static frontend files
app.use(express.static(path.join(__dirname, 'public')));

// API routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/points', require('./routes/points'));
app.use('/api/rewards', require('./routes/rewards'));
app.use('/api/redemptions', require('./routes/redemptions'));

// Serve login page as default
app.get('/', (req, res) => {
  res.redirect('/login.html');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n🎉 家庭积分系统已启动！`);
  console.log(`📱 请打开浏览器访问: http://localhost:${PORT}`);
  console.log(`👨‍👩‍👧 默认家长账号: admin / family2024\n`);
});
