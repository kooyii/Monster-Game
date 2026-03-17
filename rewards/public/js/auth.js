// Auth helpers

function requireAuth(expectedRole) {
  const token = localStorage.getItem('rp_token');
  const user = JSON.parse(localStorage.getItem('rp_user') || 'null');
  if (!token || !user) {
    window.location.href = '/login.html';
    return null;
  }
  if (expectedRole && user.role !== expectedRole) {
    window.location.href = '/login.html';
    return null;
  }
  return user;
}

function logout() {
  localStorage.removeItem('rp_token');
  localStorage.removeItem('rp_user');
  window.location.href = '/login.html';
}

function getUser() {
  return JSON.parse(localStorage.getItem('rp_user') || 'null');
}
