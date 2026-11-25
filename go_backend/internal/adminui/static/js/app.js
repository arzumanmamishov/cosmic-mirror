// Admin panel entry point: session check, layout and hash routing
// (#/customers/…). The server only serves static files; every page loads
// its data from /api/v1/admin/*.

import { h, icon, initTheme, toggleTheme, toast, errorState } from './ui.js';
import { api, getSession, logout, setUnauthorizedHandler, ApiError } from './api.js';
import * as loginPage from './pages/login.js';
import * as dashboardPage from './pages/dashboard.js';
import * as customersPage from './pages/customers.js';
import * as customerPage from './pages/customer.js';
import * as moderationPage from './pages/moderation.js';
import * as settingsPage from './pages/settings.js';
import * as auditPage from './pages/audit.js';

const NAV = [
  { id: 'dashboard', label: 'Dashboard', href: '#/', icon: 'dashboard' },
  { id: 'customers', label: 'Customers', href: '#/customers', icon: 'customers' },
  { id: 'moderation', label: 'Moderation', href: '#/moderation', icon: 'moderation' },
  { id: 'settings', label: 'Settings', href: '#/settings', icon: 'settings' },
  { id: 'audit', label: 'Audit log', href: '#/audit', icon: 'audit' },
];

const ROUTES = [
  { re: /^\/$/, page: dashboardPage, nav: 'dashboard' },
  { re: /^\/customers$/, page: customersPage, nav: 'customers' },
  { re: /^\/customers\/([0-9a-fA-F-]{36})$/, page: customerPage, nav: 'customers' },
  { re: /^\/moderation$/, page: moderationPage, nav: 'moderation' },
  { re: /^\/settings$/, page: settingsPage, nav: 'settings' },
  { re: /^\/audit$/, page: auditPage, nav: 'audit' },
];

const NOT_ADMIN = 'That account isn’t an admin. Admin access is limited to the e-mail addresses in ADMIN_EMAILS on the server.';

const app = document.getElementById('app');
let me = null;
let main = null;
let navLinks = {};
let renderSeq = 0;

function parseHash() {
  const raw = location.hash.replace(/^#/, '') || '/';
  const [path, qs] = raw.split('?');
  return { path: path || '/', query: new URLSearchParams(qs || '') };
}

function showLogin(notice) {
  me = null;
  main = null;
  document.title = 'Sign in · Lively Admin';
  app.replaceChildren();
  loginPage.render(app, { notice, onSignedIn: afterSignIn });
}

async function afterSignIn() {
  try {
    me = await api('/admin/me');
  } catch (err) {
    if (err instanceof ApiError && err.status === 403) {
      await logout();
      showLogin(NOT_ADMIN);
      return;
    }
    throw err;
  }
  renderShell();
  route();
}

function renderShell() {
  navLinks = {};
  const nav = h('nav', { class: 'nav', 'aria-label': 'Main' }, NAV.map((item) => {
    const a = h('a', { href: item.href, class: 'nav-link' }, icon(item.icon), h('span', null, item.label));
    navLinks[item.id] = a;
    return a;
  }));
  const signOut = h('button', { class: 'btn btn-ghost btn-sm', type: 'button' }, icon('logout', 16), 'Sign out');
  signOut.addEventListener('click', async () => {
    await logout();
    showLogin('You’re signed out.');
  });
  const theme = h('button', { class: 'btn btn-ghost btn-sm', type: 'button', title: 'Switch light / dark', 'aria-label': 'Switch light or dark theme' }, icon('theme', 16));
  theme.addEventListener('click', toggleTheme);

  main = h('main', { class: 'main', id: 'main', tabindex: '-1' });
  app.replaceChildren(h('div', { class: 'shell' },
    h('aside', { class: 'sidebar' },
      h('div', { class: 'brand' }, h('span', { class: 'brand-mark', 'aria-hidden': 'true' }, 'L'), h('span', null, 'Lively ', h('span', { class: 'brand-sub' }, 'Admin'))),
      nav,
      h('div', { class: 'sidebar-foot' },
        h('div', { class: 'who', title: me.email }, h('span', { class: 'who-label' }, 'Signed in as'), h('span', { class: 'who-email' }, me.email)),
        h('div', { class: 'sidebar-actions' }, signOut, theme))),
    main));
}

async function route() {
  if (!me || !main) return;
  const { path, query } = parseHash();
  const match = ROUTES.map((r) => ({ r, m: path.match(r.re) })).find((x) => x.m);
  for (const [id, a] of Object.entries(navLinks)) {
    if (match && match.r.nav === id) a.setAttribute('aria-current', 'page');
    else a.removeAttribute('aria-current');
  }
  const seq = ++renderSeq;
  main.replaceChildren();
  main.scrollTop = 0;
  window.scrollTo(0, 0);
  if (!match) {
    main.append(h('div', { class: 'empty' }, h('p', { class: 'empty-title' }, 'Page not found'), h('a', { href: '#/' }, 'Go to the dashboard')));
    return;
  }
  const { page } = match.r;
  document.title = `${page.title || 'Admin'} · Lively Admin`;
  const ctx = {
    me,
    params: match.m.slice(1),
    query,
    isCurrent: () => seq === renderSeq && !!main,
    rerender: () => route(),
    navigate: (hash) => { location.hash = hash; },
  };
  try {
    await page.render(main, ctx);
  } catch (err) {
    if (ctx.isCurrent() && !(err instanceof ApiError && err.status === 401)) {
      main.append(errorState(err, () => route()));
    }
  }
}

async function boot() {
  initTheme();
  setUnauthorizedHandler(() => {
    if (me) {
      toast('Your session has ended. Please sign in again.', 'warning');
      showLogin();
    }
  });
  window.addEventListener('hashchange', route);
  if (!getSession()) {
    showLogin();
    return;
  }
  try {
    await afterSignIn();
  } catch (err) {
    if (err instanceof ApiError && err.status === 401) showLogin();
    else app.replaceChildren(h('div', { class: 'boot' }, errorState(err, () => location.reload())));
  }
}

boot();
