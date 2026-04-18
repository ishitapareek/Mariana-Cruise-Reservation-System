let isLoggedIn = false;
let currentUser = null;

const CRUISE_MAP = [
  { index: 0, id: 1, name: "Atlantic Explorer", route: "Miami → Barcelona", nights: 9, price: 30000 },
  { index: 1, id: 2, name: "Desert Pearl Voyage", route: "Dubai → Singapore", nights: 7, price: 45000 },
  { index: 2, id: 3, name: "Pacific Odyssey", route: "Singapore → Sydney", nights: 10, price: 80000 },
  { index: 3, id: 4, name: "European Escape", route: "Barcelona → Miami", nights: 9, price: 35000 }
];

const SUITE_MAP = [
  { code: 1, name: "Interior Suite", pricePerNight: 2000 },
  { code: 2, name: "Ocean View Suite", pricePerNight: 4000 },
  { code: 3, name: "Balcony Suite", pricePerNight: 6000 },
  { code: 4, name: "Royal Suite", pricePerNight: 10000 }
];

const ACTIVITY_MAP = [
  { code: 1, name: "Scuba Diving", price: 3000 },
  { code: 2, name: "Wine Tasting", price: 2000 },
  { code: 3, name: "Casino Night", price: 1500 },
  { code: 4, name: "Spa Therapy", price: 4000 },
  { code: 5, name: "Sky Diving Sim", price: 3500 }
];

let selectedCruiseIndex = 0;
let selectedSuiteIndex = 1;
let selectedActivities = new Set([0]);

let editingReservationId = null;
let editCruiseIndex = 0;
let editSuiteIndex = -1;
let editActivities = new Set();


// Nav scroll effect
window.addEventListener('scroll', () => {
  const nav = document.getElementById('navbar');
  if (window.scrollY > 50) nav.classList.add('scrolled');
  else nav.classList.remove('scrolled');
});


// Page navigation
function showPage(page) {
  if (['reservations'].includes(page) && !isLoggedIn) {
    showToast("⚠️ Please sign in first to access bookings");
    page = 'auth';
  }

  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  const target = document.getElementById(`page-${page}`);
  if (target) target.classList.add('active');
  window.scrollTo(0, 0);

  if (page === 'reservations' && isLoggedIn) {
    loadMyBookings();
    loadPaymentReservations();
    loadProfile();
  }
}


// Auth tabs
function switchAuthTab(tab) {
  document.querySelectorAll('.auth-tab').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.auth-form').forEach(f => f.classList.remove('active'));

  if (tab === 'login') {
    document.querySelectorAll('.auth-tab')[0].classList.add('active');
    document.getElementById('auth-login').classList.add('active');
  } else {
    document.querySelectorAll('.auth-tab')[1].classList.add('active');
    document.getElementById('auth-signup').classList.add('active');
  }
}


// Login
async function handleLogin() {
  const email = document.getElementById("login-email").value.trim();
  const password = document.getElementById("login-password").value.trim();

  if (!email || !password) {
    showToast("⚠️ Please enter email and password");
    return;
  }

  try {
    const res = await fetch("/api/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      credentials: "include",
      body: JSON.stringify({ email, password })
    });
    const data = await res.json();

    if (res.ok) {
      isLoggedIn = true;
      document.getElementById("login-email").value = "";
      document.getElementById("login-password").value = "";
      await loadUser();
      showToast("✅ Welcome back! Login successful");
      showPage("home");
    } else {
      showToast("❌ " + (data.error || "Login failed"));
    }
  } catch (err) {
    console.error(err);
    showToast("❌ Server error. Try again.");
  }
}


// Signup
async function handleSignup() {
  const name = document.getElementById("name").value.trim();
  const email = document.getElementById("email").value.trim();
  const mobile = document.getElementById("phone").value.trim();
  const password = document.getElementById("password").value.trim();

  if (!name || !email || !mobile || !password) {
    showToast("⚠️ Please fill all required fields");
    return;
  }

  try {
    const res = await fetch("/api/register", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      credentials: "include",
      body: JSON.stringify({ name, email, mobile, password })
    });
    const result = await res.json();

    if (res.ok) {
      document.getElementById("name").value = "";
      document.getElementById("email").value = "";
      document.getElementById("phone").value = "";
      document.getElementById("password").value = "";
      showToast("✅ Account created! Please sign in.");
      switchAuthTab('login');
    } else {
      showToast("❌ " + (result.error || "Signup failed"));
    }
  } catch (err) {
    console.error(err);
    showToast("❌ Server error. Try again.");
  }
}


// Load user session
async function loadUser() {
  try {
    const res = await fetch("/api/me", { credentials: "include" });
    const data = await res.json();

    const navUser = document.getElementById("nav-user");
    const createBtn = document.getElementById("create-account-btn");
    const reserveBtn = document.getElementById("reservation-btn");

    if (data.user) {
      isLoggedIn = true;
      currentUser = data.user;
      if (navUser) {
        navUser.innerText = data.user.Full_Name;
        navUser.setAttribute("onclick", "showPage('reservations');switchResSection('profile')");
      }
      if (createBtn) createBtn.style.display = "none";
      if (reserveBtn) reserveBtn.style.display = "inline-block";
    } else {
      isLoggedIn = false;
      currentUser = null;
      if (navUser) {
        navUser.innerText = "Sign In";
        navUser.setAttribute("onclick", "showPage('auth')");
      }
      if (createBtn) createBtn.style.display = "inline-block";
      if (reserveBtn) reserveBtn.style.display = "none";
    }
  } catch (err) {
    console.error("loadUser error:", err);
  }
}


// Logout
async function logout() {
  try {
    await fetch("/api/logout", { credentials: "include" });
    isLoggedIn = false;
    currentUser = null;
    showToast("Signed out successfully");
    await loadUser();
    showPage("home");
  } catch (err) {
    console.error(err);
    location.reload();
  }
}


// Load cruises for home page
async function loadCruises() {
  try {
    const res = await fetch("/api/cruises");
    const cruises = await res.json();
    const container = document.getElementById("cruises-container");
    if (!container) return;

    container.innerHTML = "";
    const images = [
      "/static/images/Atlantic Explorer Cruise.jpeg",
      "/static/images/Desert Pearl Voyage Cruise.jpg",
      "/static/images/Pacific Odyssey Cruise.jpg",
      "/static/images/European Escape Cruise.jpg"
    ];

    cruises.slice(0, 4).forEach((cruise, i) => {
      const startDate = new Date(cruise.Start_Date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
      const endDate = new Date(cruise.End_Date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
      const price = Number(cruise.Price_Base).toLocaleString('en-IN');

      const card = document.createElement("div");
      card.className = "cruise-card";
      card.innerHTML = `
        <div class="cruise-card-img" style="background:linear-gradient(135deg,rgba(28,43,42,0.2),rgba(69,124,156,0.2)),url('${images[i % 4]}') center/cover no-repeat;display:flex;align-items:center;justify-content:center;">
          <span style="font-size:64px;opacity:0.3;">${icons[i % 4]}</span>
        </div>
        <div class="cruise-card-body">
          <div class="cruise-route"><span>Cruise #${cruise.Cruise_Id}</span></div>
          <div class="cruise-name">${cruise.Cruise_Name}</div>
          <div class="cruise-meta">
            <div class="cruise-meta-item">📅 ${startDate}</div>
            <div class="cruise-meta-item">→ ${endDate}</div>
          </div>
          <div class="cruise-footer">
            <div class="cruise-price">₹${price} <span>/person</span></div>
            <button class="btn-sm" onclick="event.stopPropagation();showPage('cruises')">View →</button>
          </div>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (err) {
    console.error("loadCruises error:", err);
  }
}


// Reservation section switching
function switchResSection(section) {
  document.querySelectorAll('.res-nav-item').forEach(item => item.classList.remove('active'));
  const navItem = document.getElementById(`resnav-${section}`);
  if (navItem) navItem.classList.add('active');

  document.querySelectorAll('.res-section').forEach(s => s.classList.remove('active'));
  const sec = document.getElementById(`res-${section}`);
  if (sec) sec.classList.add('active');

  if (section === 'my-res') loadMyBookings();
  if (section === 'payment') loadPaymentReservations();
  if (section === 'profile') loadProfile();
}


// Cruise selection (reservation form)
function selectCruise(el) {
  document.querySelectorAll('.cruise-select-item').forEach(item => item.classList.remove('selected'));
  el.classList.add('selected');
  document.querySelectorAll('.cruise-select-item').forEach((item, i) => {
    if (item === el) selectedCruiseIndex = i;
  });
  updateCostSummary();
}

function selectSuite(el) {
  document.querySelectorAll('.suite-select-item').forEach(item => item.classList.remove('selected'));
  el.classList.add('selected');
  document.querySelectorAll('.suite-select-item').forEach((item, i) => {
    if (item === el) selectedSuiteIndex = i;
  });
  updateCostSummary();
}

function toggleActivity(el) {
  el.classList.toggle('selected');
  const items = document.querySelectorAll('.activity-select-item');
  selectedActivities.clear();
  items.forEach((item, i) => {
    if (item.classList.contains('selected')) selectedActivities.add(i);
  });
  updateCostSummary();
}

function addPassenger() {
  const list = document.getElementById('passenger-list');
  const row = document.createElement('div');
  row.className = 'passenger-row';
  row.innerHTML = `
    <div class="form-group">
      <label>Full Name</label>
      <input type="text" placeholder="Passenger name">
    </div>
    <div class="form-group" style="max-width:140px;">
      <label>Date of Birth</label>
      <input type="date">
    </div>
    <div class="form-group" style="max-width:120px;">
      <label>Gender</label>
      <select>
        <option>Female</option>
        <option>Male</option>
        <option>Other</option>
      </select>
    </div>
    <button type="button" class="btn-danger" style="height:44px;align-self:flex-end;padding:10px 14px;font-size:16px;border-radius:10px;" onclick="this.parentElement.remove();updateCostSummary()">✕</button>
  `;
  list.appendChild(row);
  updateCostSummary();
}


// Cost summary calculation
function updateCostSummary() {
  const cruise = CRUISE_MAP[selectedCruiseIndex];
  const suite = SUITE_MAP[selectedSuiteIndex];
  const nights = cruise.nights;
  const baseCost = cruise.price;
  const suiteCost = suite.pricePerNight * nights;

  let activityCost = 0;
  let activityHtml = '';
  selectedActivities.forEach(i => {
    const act = ACTIVITY_MAP[i];
    activityCost += act.price;
    activityHtml += `
      <div class="cost-row">
        <span class="cost-label">${act.name} × 1</span>
        <span class="cost-val">₹${act.price.toLocaleString('en-IN')}</span>
      </div>`;
  });

  const total = baseCost + suiteCost + activityCost;
  const summary = document.querySelector('.cost-summary');
  if (summary) {
    summary.innerHTML = `
      <h4>Estimated Total</h4>
      <div class="cost-row">
        <span class="cost-label">Cruise (${cruise.name})</span>
        <span class="cost-val">₹${baseCost.toLocaleString('en-IN')}</span>
      </div>
      <div class="cost-row">
        <span class="cost-label">${suite.name} × ${nights} nights</span>
        <span class="cost-val">₹${suiteCost.toLocaleString('en-IN')}</span>
      </div>
      ${activityHtml}
      <div class="cost-row cost-total">
        <span class="cost-label">Total</span>
        <span class="cost-val">₹${total.toLocaleString('en-IN')}</span>
      </div>
    `;
  }
}


// Confirm reservation
async function confirmReservation() {
  if (!isLoggedIn) {
    showToast("⚠️ Please sign in first");
    showPage('auth');
    return;
  }

  const cruise = CRUISE_MAP[selectedCruiseIndex];
  const passengers = document.querySelectorAll('#passenger-list .passenger-row').length;

  try {
    const res = await fetch("/api/book", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      credentials: "include",
      body: JSON.stringify({ cruise_id: cruise.id, members: passengers })
    });
    const data = await res.json();

    if (res.ok) {
      openModal('success');
      loadMyBookings();
    } else {
      showToast("❌ " + (data.error || "Booking failed"));
    }
  } catch (err) {
    console.error(err);
    showToast("❌ Server error. Try again.");
  }
}


// Load user's bookings
async function loadMyBookings() {
  if (!isLoggedIn) return;

  try {
    const res = await fetch("/api/my-bookings", { credentials: "include" });
    if (!res.ok) return;
    const data = await res.json();
    const container = document.getElementById("my-bookings-container");
    if (!container) return;

    if (data.length === 0) {
      container.innerHTML = `
        <div style="text-align:center;padding:60px 20px;">
          <div style="font-size:64px;margin-bottom:20px;">🚢</div>
          <h3 style="font-family:'Cormorant Garamond',serif;font-size:28px;margin-bottom:10px;">No Reservations Yet</h3>
          <p style="color:var(--text-muted);font-size:14px;margin-bottom:28px;">Start planning your dream voyage today!</p>
          <button class="btn-primary" onclick="switchResSection('new')">Make Your First Reservation →</button>
        </div>
      `;
      return;
    }

    let html = '';
    data.forEach(r => {
      const startDate = new Date(r.Start_Date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
      const endDate = new Date(r.End_Date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
      const statusClass = r.Status_Name === 'Confirmed' ? 'status-confirmed' : 'status-pending';
      const statusName = r.Status_Name || 'Pending';
      const isPending = r.Status_Name !== 'Confirmed';

      let footerHtml = isPending
        ? `<button class="btn-ghost" onclick="editReservation(${r.Reservation_Id})">✏️ Edit Reservation</button>
           <button class="btn-ghost" onclick="switchResSection('payment')">💳 Make Payment</button>`
        : `<span style="color:var(--forest);font-size:13px;font-weight:500;display:flex;align-items:center;gap:6px;">✅ Confirmed — No pending payments</span>`;

      html += `
        <div class="res-card">
          <div class="res-card-header">
            <div>
              <div class="res-card-title">${r.Cruise_Name}</div>
              <div class="res-card-id">Reservation #${r.Reservation_Id}</div>
            </div>
            <span class="status-badge ${statusClass}">${statusName}</span>
          </div>
          <div class="res-card-details">
            <div class="res-detail">
              <div class="res-detail-label">Departure</div>
              <div class="res-detail-val">${startDate}</div>
            </div>
            <div class="res-detail">
              <div class="res-detail-label">Arrival</div>
              <div class="res-detail-val">${endDate}</div>
            </div>
            <div class="res-detail">
              <div class="res-detail-label">Members</div>
              <div class="res-detail-val">${r.Members || '—'}</div>
            </div>
            <div class="res-detail">
              <div class="res-detail-label">Status</div>
              <div class="res-detail-val">${statusName}</div>
            </div>
          </div>
          <div class="res-card-footer">${footerHtml}</div>
        </div>
      `;
    });
    container.innerHTML = html;
  } catch (err) {
    console.error("loadMyBookings error:", err);
  }
}


// Payment reservations dropdown
async function loadPaymentReservations() {
  if (!isLoggedIn) return;

  try {
    const res = await fetch("/api/my-bookings", { credentials: "include" });
    if (!res.ok) return;
    const data = await res.json();
    const select = document.getElementById("payment-reservation-select");
    if (!select) return;

    select.innerHTML = "";
    const pendingBookings = data.filter(r => r.Status_Name !== 'Confirmed');

    if (pendingBookings.length === 0) {
      select.innerHTML = '<option>No pending payments</option>';
      const payBtn = document.querySelector('#res-payment .btn-full');
      if (payBtn) payBtn.disabled = true;

      const amountInput = document.getElementById("payment-amount");
      if (amountInput) amountInput.value = "—";

      const paymentForm = document.querySelector('.payment-form');
      const noPendingMsg = document.getElementById('no-pending-msg');
      if (!noPendingMsg && paymentForm) {
        const msgDiv = document.createElement('div');
        msgDiv.id = 'no-pending-msg';
        msgDiv.style.cssText = 'text-align:center;padding:40px 20px;';
        msgDiv.innerHTML = `
          <div style="font-size:56px;margin-bottom:16px;">🎉</div>
          <h3 style="font-family:'Cormorant Garamond',serif;font-size:24px;margin-bottom:8px;color:var(--forest);">All Payments Complete!</h3>
          <p style="color:var(--text-muted);font-size:14px;">You have no pending payments. All your reservations are confirmed.</p>
        `;
        paymentForm.parentNode.insertBefore(msgDiv, paymentForm);
        paymentForm.style.display = 'none';
      }
      return;
    }

    const paymentForm = document.querySelector('.payment-form');
    const noPendingMsg = document.getElementById('no-pending-msg');
    if (noPendingMsg) noPendingMsg.remove();
    if (paymentForm) paymentForm.style.display = '';
    const payBtn = document.querySelector('#res-payment .btn-full');
    if (payBtn) payBtn.disabled = false;

    pendingBookings.forEach(r => {
      const opt = document.createElement("option");
      opt.value = r.Reservation_Id;
      opt.textContent = `#${r.Reservation_Id} — ${r.Cruise_Name} (Pending)`;
      select.appendChild(opt);
    });

    loadReservationCost();
  } catch (err) {
    console.error("loadPaymentReservations error:", err);
  }
}


// Auto-fetch reservation cost
async function loadReservationCost() {
  const select = document.getElementById("payment-reservation-select");
  const amountInput = document.getElementById("payment-amount");
  if (!select || !amountInput) return;

  const resId = select.value;
  if (!resId || isNaN(resId)) {
    amountInput.value = "—";
    return;
  }

  amountInput.value = "Loading...";

  try {
    const res = await fetch(`/api/cost/${resId}`, { credentials: "include" });
    if (!res.ok) {
      amountInput.value = "—";
      return;
    }
    const data = await res.json();
    amountInput.value = `₹${(data.total || 0).toLocaleString('en-IN')}`;
  } catch (err) {
    console.error("loadReservationCost error:", err);
    amountInput.value = "—";
  }
}


// Load profile
function loadProfile() {
  if (!currentUser) return;

  const avatar = document.getElementById("profile-avatar");
  const nameEl = document.getElementById("profile-display-name");
  const regEl = document.getElementById("profile-reg-info");
  const nameInput = document.getElementById("profile-name");
  const emailInput = document.getElementById("profile-email");
  const mobileInput = document.getElementById("profile-mobile");

  if (avatar) avatar.textContent = (currentUser.Full_Name || "U")[0].toUpperCase();
  if (nameEl) nameEl.textContent = currentUser.Full_Name || "User";
  if (regEl) regEl.textContent = `Member since 2026 · Registration #${currentUser.Registration_Id || '—'}`;
  if (nameInput) nameInput.value = currentUser.Full_Name || "";
  if (emailInput) emailInput.value = currentUser.Email || "";
  if (mobileInput) mobileInput.value = currentUser.Mobile_Number || "";
}


// Update profile
async function handleProfileUpdate() {
  if (!isLoggedIn) {
    showToast("⚠️ Please sign in first");
    return;
  }

  const name = document.getElementById("profile-name").value.trim();
  const email = document.getElementById("profile-email").value.trim();
  const mobile = document.getElementById("profile-mobile").value.trim();
  const password = document.getElementById("profile-password").value.trim();
  const confirmPassword = document.getElementById("profile-confirm-password").value.trim();

  if (!name || !email) {
    showToast("⚠️ Name and email are required");
    return;
  }
  if (password && password !== confirmPassword) {
    showToast("⚠️ Passwords do not match");
    return;
  }

  try {
    const body = { name, email, mobile };
    if (password) body.password = password;

    const res = await fetch("/api/profile", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      credentials: "include",
      body: JSON.stringify(body)
    });
    const data = await res.json();

    if (res.ok) {
      showToast("✅ Profile updated successfully!");
      document.getElementById("profile-password").value = "";
      document.getElementById("profile-confirm-password").value = "";
      await loadUser();
      loadProfile();
    } else {
      showToast("❌ " + (data.error || "Update failed"));
    }
  } catch (err) {
    console.error(err);
    showToast("❌ Server error. Try again.");
  }
}


// Cruise filtering
function filterCruises(filter, btnEl) {
  document.querySelectorAll('.filters-bar .filter-chip').forEach(c => c.classList.remove('active'));
  if (btnEl) btnEl.classList.add('active');

  const cards = document.querySelectorAll('.cruises-page-grid .cruise-detail-card');
  const today = new Date();

  cards.forEach(card => {
    const price = parseInt(card.dataset.price) || 0;
    const nights = parseInt(card.dataset.nights) || 0;
    const startDate = new Date(card.dataset.start);
    let show = true;

    switch (filter) {
      case 'under50k': show = price < 50000; break;
      case 'long': show = nights >= 9; break;
      case 'upcoming': show = startDate > today; break;
      default: show = true;
    }
    card.style.display = show ? '' : 'none';
  });
}


// Payment method selection
function selectPayment(el) {
  document.querySelectorAll('.payment-method').forEach(m => m.classList.remove('selected'));
  el.classList.add('selected');
}


// Make payment
async function handlePayment() {
  if (!isLoggedIn) {
    showToast("⚠️ Please sign in first");
    return;
  }

  const select = document.getElementById("payment-reservation-select");
  if (!select || !select.value) {
    showToast("⚠️ Please select a reservation");
    return;
  }

  const resId = select.value;
  const amountInput = document.getElementById("payment-amount");
  const amountStr = amountInput ? amountInput.value.replace(/[₹,]/g, '').trim() : '0';
  const amount = parseInt(amountStr) || 0;

  if (amount <= 0) {
    showToast("⚠️ Please enter a valid amount");
    return;
  }

  try {
    const res = await fetch("/api/pay", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      credentials: "include",
      body: JSON.stringify({ reservation_id: parseInt(resId), amount })
    });
    const data = await res.json();

    if (res.ok) {
      openModal('payment-success');
      loadMyBookings();
      loadPaymentReservations();
    } else {
      showToast("❌ " + (data.error || "Payment failed"));
    }
  } catch (err) {
    console.error(err);
    showToast("❌ Server error. Try again.");
  }
}


// Modal
function openModal(type) {
  const overlay = document.getElementById('modal-overlay');
  const icon = document.getElementById('modal-icon');
  const title = document.getElementById('modal-title');
  const desc = document.getElementById('modal-desc');
  const actions = document.getElementById('modal-actions');

  if (type === 'success') {
    icon.textContent = '✅';
    title.textContent = 'Reservation Confirmed!';
    desc.textContent = 'Your reservation has been successfully created. You can view and manage it from your bookings.';
    actions.innerHTML = '<button class="btn-full" onclick="closeModalDirect();switchResSection(\'my-res\')">View My Reservations</button>';
  } else if (type === 'payment-success') {
    icon.textContent = '💰';
    title.textContent = 'Payment Successful!';
    desc.textContent = 'Your payment has been processed. Your reservation status has been updated to confirmed.';
    actions.innerHTML = '<button class="btn-full" onclick="closeModalDirect();switchResSection(\'my-res\')">View My Reservations</button>';
  }

  overlay.classList.add('open');
}

function closeModal(event) {
  if (event.target === document.getElementById('modal-overlay')) {
    document.getElementById('modal-overlay').classList.remove('open');
  }
}

function closeModalDirect() {
  document.getElementById('modal-overlay').classList.remove('open');
}


// Toast notifications
function showToast(message) {
  const toast = document.getElementById('toast');
  const msgSpan = document.getElementById('toast-msg');
  const iconSpan = document.getElementById('toast-icon');
  if (!toast || !msgSpan) return;

  const match = message.match(/^([\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}✅❌⚠️👋])\s*/u);
  if (match && iconSpan) {
    iconSpan.textContent = match[1];
    msgSpan.textContent = message.replace(match[0], '');
  } else {
    if (iconSpan) iconSpan.textContent = '✅';
    msgSpan.textContent = message;
  }

  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 3500);
}


// Edit reservation
async function editReservation(resId) {
  if (!isLoggedIn) {
    showToast('⚠️ Please sign in first');
    return;
  }

  editingReservationId = resId;

  try {
    const res = await fetch(`/api/reservation/${resId}`, { credentials: 'include' });
    if (!res.ok) {
      showToast('❌ Could not load reservation details');
      return;
    }
    const data = await res.json();

    editCruiseIndex = CRUISE_MAP.findIndex(c => c.id === data.Cruise_Id);
    if (editCruiseIndex < 0) editCruiseIndex = 0;

    editSuiteIndex = (data.suites && data.suites.length > 0)
      ? SUITE_MAP.findIndex(s => s.code === data.suites[0].Suite_Code)
      : -1;

    editActivities = new Set(data.activities || []);
    buildEditForm(data);
    switchResSection('edit');
  } catch (err) {
    console.error(err);
    showToast('❌ Error loading reservation');
  }
}

function buildEditForm(data) {
  const container = document.getElementById('res-edit');
  if (!container) return;

  let cruiseHtml = '';
  CRUISE_MAP.forEach((c, i) => {
    const sel = i === editCruiseIndex ? 'selected' : '';
    cruiseHtml += `<div class="cruise-select-item ${sel}" onclick="editSelectCruise(this, ${i})">
      <h4>${c.name}</h4>
      <p>${c.route} · ${c.nights} nights</p>
    </div>`;
  });

  let passHtml = '';
  const passengers = data.passengers || [];
  if (passengers.length === 0) {
    for (let m = 0; m < (data.Members || 1); m++) {
      passHtml += `<div class="passenger-row">
        <div class="form-group"><label>Full Name</label><input type="text" placeholder="Passenger name" class="edit-passenger-name"></div>
        <button type="button" class="btn-danger" style="height:44px;align-self:flex-end;padding:10px 14px;font-size:16px;border-radius:10px;" onclick="this.parentElement.remove()">✕</button>
      </div>`;
    }
  } else {
    passengers.forEach(p => {
      passHtml += `<div class="passenger-row">
        <div class="form-group"><label>Full Name</label><input type="text" value="${p.Full_Name || ''}" class="edit-passenger-name"></div>
        <button type="button" class="btn-danger" style="height:44px;align-self:flex-end;padding:10px 14px;font-size:16px;border-radius:10px;" onclick="this.parentElement.remove()">✕</button>
      </div>`;
    });
  }

  let suiteHtml = '';
  const suiteEmojis = ['🛏️', '🌊', '🌿', '👑'];
  SUITE_MAP.forEach((s, i) => {
    const sel = i === editSuiteIndex ? 'selected' : '';
    suiteHtml += `<div class="suite-select-item ${sel}" onclick="editSelectSuite(this, ${i})">
      <h4>${suiteEmojis[i]} ${s.name}</h4>
      <p>₹${s.pricePerNight.toLocaleString('en-IN')}/night</p>
    </div>`;
  });

  let actHtml = '';
  const actEmojis = ['🤿', '🍷', '🎰', '💆', '🪂'];
  ACTIVITY_MAP.forEach((a, i) => {
    const sel = editActivities.has(a.code) ? 'selected' : '';
    actHtml += `<div class="activity-select-item ${sel}" onclick="editToggleActivity(this, ${a.code})">
      <div class="activity-select-emoji">${actEmojis[i]}</div>
      <div class="activity-select-info">
        <h4>${a.name}</h4>
        <p>₹${a.price.toLocaleString('en-IN')}</p>
      </div>
    </div>`;
  });

  container.innerHTML = `
    <div style="display:flex;align-items:center;gap:12px;margin-bottom:8px;">
      <button class="btn-ghost" onclick="cancelEdit()" style="padding:8px 12px;">← Back</button>
      <div>
        <h2 style="margin:0;">Edit Reservation #${data.Reservation_Id}</h2>
        <p style="margin:4px 0 0;color:var(--text-muted);font-size:14px;">Modify your cruise, passengers, suite, and activities below.</p>
      </div>
    </div>
    <div class="reservation-form">
      <div class="res-step">
        <div class="step-header">
          <div class="step-num">1</div>
          <div><div class="step-title">Change Cruise</div><div class="step-sub">Select a different voyage</div></div>
        </div>
        <div class="cruise-select-grid">${cruiseHtml}</div>
      </div>
      <div class="res-step">
        <div class="step-header">
          <div class="step-num">2</div>
          <div><div class="step-title">Update Passengers</div><div class="step-sub">Add or remove travelers</div></div>
        </div>
        <div id="edit-passenger-list">${passHtml}</div>
        <button class="btn-add" onclick="addEditPassenger()">+ Add Another Passenger</button>
      </div>
      <div class="res-step">
        <div class="step-header">
          <div class="step-num">3</div>
          <div><div class="step-title">Change Suite</div><div class="step-sub">Select your accommodation</div></div>
        </div>
        <div class="suite-select-grid">${suiteHtml}</div>
      </div>
      <div class="res-step">
        <div class="step-header">
          <div class="step-num">4</div>
          <div><div class="step-title">Update Activities</div><div class="step-sub">Toggle activities on or off</div></div>
        </div>
        <div class="activities-select-grid">${actHtml}</div>
      </div>
      <div id="edit-cost-summary" class="cost-summary"></div>
      <div style="display:flex;gap:12px;margin-top:24px;">
        <button class="btn-full" onclick="saveReservation()">Save Changes →</button>
        <button class="btn-ghost" onclick="cancelEdit()">Cancel</button>
      </div>
    </div>
  `;
  updateEditCostSummary();
}

function editSelectCruise(el, index) {
  el.closest('.cruise-select-grid').querySelectorAll('.cruise-select-item').forEach(item => item.classList.remove('selected'));
  el.classList.add('selected');
  editCruiseIndex = index;
  updateEditCostSummary();
}

function editSelectSuite(el, index) {
  el.closest('.suite-select-grid').querySelectorAll('.suite-select-item').forEach(item => item.classList.remove('selected'));
  el.classList.add('selected');
  editSuiteIndex = index;
  updateEditCostSummary();
}

function editToggleActivity(el, code) {
  el.classList.toggle('selected');
  if (editActivities.has(code)) editActivities.delete(code);
  else editActivities.add(code);
  updateEditCostSummary();
}

function addEditPassenger() {
  const list = document.getElementById('edit-passenger-list');
  const row = document.createElement('div');
  row.className = 'passenger-row';
  row.innerHTML = `
    <div class="form-group"><label>Full Name</label><input type="text" placeholder="Passenger name" class="edit-passenger-name"></div>
    <button type="button" class="btn-danger" style="height:44px;align-self:flex-end;padding:10px 14px;font-size:16px;border-radius:10px;" onclick="this.parentElement.remove()">✕</button>
  `;
  list.appendChild(row);
}

function updateEditCostSummary() {
  const cruise = CRUISE_MAP[editCruiseIndex];
  const nights = cruise.nights;
  const baseCost = cruise.price;

  let suiteCost = 0;
  let suiteHtml = '';
  if (editSuiteIndex >= 0) {
    const suite = SUITE_MAP[editSuiteIndex];
    suiteCost = suite.pricePerNight * nights;
    suiteHtml = `<div class="cost-row">
      <span class="cost-label">${suite.name} × ${nights} nights</span>
      <span class="cost-val">₹${suiteCost.toLocaleString('en-IN')}</span>
    </div>`;
  }

  let activityCost = 0;
  let activityHtml = '';
  editActivities.forEach(code => {
    const act = ACTIVITY_MAP.find(a => a.code === code);
    if (act) {
      activityCost += act.price;
      activityHtml += `<div class="cost-row">
        <span class="cost-label">${act.name}</span>
        <span class="cost-val">₹${act.price.toLocaleString('en-IN')}</span>
      </div>`;
    }
  });

  const total = baseCost + suiteCost + activityCost;
  const summary = document.getElementById('edit-cost-summary');
  if (summary) {
    summary.innerHTML = `
      <h4>Updated Estimated Total</h4>
      <div class="cost-row">
        <span class="cost-label">Cruise (${cruise.name})</span>
        <span class="cost-val">₹${baseCost.toLocaleString('en-IN')}</span>
      </div>
      ${suiteHtml}
      ${activityHtml}
      <div class="cost-row cost-total">
        <span class="cost-label">Total</span>
        <span class="cost-val">₹${total.toLocaleString('en-IN')}</span>
      </div>
    `;
  }
}

async function saveReservation() {
  if (!editingReservationId) return;

  const cruise = CRUISE_MAP[editCruiseIndex];
  const passengerInputs = document.querySelectorAll('#edit-passenger-list .edit-passenger-name');
  const passengers = [];
  passengerInputs.forEach(input => {
    const name = input.value.trim();
    if (name) passengers.push({ name });
  });

  const members = Math.max(passengers.length, 1);
  const suiteCode = editSuiteIndex >= 0 ? SUITE_MAP[editSuiteIndex].code : null;
  const activities = Array.from(editActivities);

  try {
    const res = await fetch(`/api/reservation/${editingReservationId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({
        cruise_id: cruise.id,
        members,
        passengers,
        suite_code: suiteCode,
        suite_nights: cruise.nights,
        activities
      })
    });
    const data = await res.json();

    if (res.ok) {
      showToast('✅ Reservation updated successfully!');
      editingReservationId = null;
      switchResSection('my-res');
      loadMyBookings();
    } else {
      showToast('❌ ' + (data.error || 'Update failed'));
    }
  } catch (err) {
    console.error(err);
    showToast('❌ Server error. Try again.');
  }
}

function cancelEdit() {
  editingReservationId = null;
  switchResSection('my-res');
}


// Initialization
async function initApp() {
  await loadUser();
  loadCruises();
  if (isLoggedIn) loadMyBookings();
  updateCostSummary();
}