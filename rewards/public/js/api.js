// Shared API fetch wrapper
async function apiFetch(path, options = {}) {
  const token = localStorage.getItem('rp_token');
  const res = await fetch('/api' + path, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
      ...(options.headers || {})
    },
    body: options.body ? (typeof options.body === 'string' ? options.body : JSON.stringify(options.body)) : undefined
  });

  if (res.status === 401) {
    localStorage.removeItem('rp_token');
    localStorage.removeItem('rp_user');
    window.location.href = '/login.html';
    return null;
  }

  return res;
}

function showToast(message, type = 'success') {
  let toast = document.getElementById('toast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'toast';
    toast.className = 'fixed bottom-4 right-4 z-50 px-6 py-3 rounded-xl shadow-lg text-white font-medium transition-all duration-300 translate-y-20 opacity-0';
    document.body.appendChild(toast);
  }
  toast.textContent = message;
  toast.className = `fixed bottom-4 right-4 z-50 px-6 py-3 rounded-xl shadow-lg text-white font-medium transition-all duration-300 ${type === 'success' ? 'bg-green-500' : 'bg-red-500'}`;
  toast.style.transform = 'translateY(0)';
  toast.style.opacity = '1';
  setTimeout(() => {
    toast.style.transform = 'translateY(80px)';
    toast.style.opacity = '0';
  }, 3000);
}

function showModal(title, message, onConfirm) {
  let overlay = document.getElementById('modal-overlay');
  if (!overlay) {
    overlay = document.createElement('div');
    overlay.id = 'modal-overlay';
    overlay.className = 'fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center';
    document.body.appendChild(overlay);
  }
  overlay.innerHTML = `
    <div class="bg-white rounded-2xl p-6 max-w-sm w-full mx-4 shadow-2xl">
      <h3 class="text-lg font-bold mb-2">${title}</h3>
      <p class="text-gray-600 mb-6">${message}</p>
      <div class="flex gap-3 justify-end">
        <button id="modal-cancel" class="px-4 py-2 rounded-lg border border-gray-300 text-gray-700 hover:bg-gray-50">取消</button>
        <button id="modal-confirm" class="px-4 py-2 rounded-lg bg-red-500 text-white hover:bg-red-600">确认</button>
      </div>
    </div>
  `;
  overlay.style.display = 'flex';
  document.getElementById('modal-cancel').onclick = () => overlay.style.display = 'none';
  document.getElementById('modal-confirm').onclick = () => {
    overlay.style.display = 'none';
    onConfirm();
  };
}
