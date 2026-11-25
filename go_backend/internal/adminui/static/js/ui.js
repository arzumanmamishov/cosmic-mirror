// Small DOM + formatting helpers shared by every page. Everything is built
// with createElement/textContent — never innerHTML — so customer-supplied
// text (names, posts, report details) can't inject markup.

const SVG_NS = 'http://www.w3.org/2000/svg';

function appendChildren(el, children) {
  for (const c of children.flat(Infinity)) {
    if (c == null || c === false || c === '') continue;
    el.append(c instanceof Node ? c : String(c));
  }
}

function applyProps(el, props) {
  if (!props) return;
  for (const [k, v] of Object.entries(props)) {
    if (v == null || v === false) continue;
    if (k === 'class') el.setAttribute('class', v);
    else if (k === 'text') el.textContent = v;
    else if (k === 'style') {
      for (const [p, val] of Object.entries(v)) {
        if (p.startsWith('--')) el.style.setProperty(p, val);
        else el.style[p] = val;
      }
    } else if (k === 'dataset') Object.assign(el.dataset, v);
    else if (k.startsWith('on') && typeof v === 'function') el.addEventListener(k.slice(2), v);
    else if (k === 'value' && 'value' in el) el.value = v;
    else if (v === true) el.setAttribute(k, '');
    else el.setAttribute(k, String(v));
  }
}

/** h('div', {class: 'x', onclick: fn}, child, 'text', [more]) */
export function h(tag, props, ...children) {
  const el = document.createElement(tag);
  applyProps(el, props);
  appendChildren(el, children);
  return el;
}

/** SVG flavour of h(). */
export function s(tag, props, ...children) {
  const el = document.createElementNS(SVG_NS, tag);
  applyProps(el, props);
  appendChildren(el, children);
  return el;
}

// ----- Icons (20px, stroke-based) -----

const ICONS = {
  dashboard: ['M3 3h6v8H3z', 'M11 3h6v5h-6z', 'M11 10h6v7h-6z', 'M3 13h6v4H3z'],
  customers: ['M7 9a3 3 0 1 0 0-6 3 3 0 0 0 0 6z', 'M1.5 17c.6-3 2.8-5 5.5-5s4.9 2 5.5 5', 'M13 3.2a3 3 0 0 1 0 5.6', 'M15 12.3c1.8.6 3.1 2.4 3.5 4.7'],
  moderation: ['M4 18V3', 'M4 3h10l-2 4 2 4H4'],
  settings: ['M10 12.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z', 'M10 1.5v2.2M10 16.3v2.2M3.99 3.99l1.55 1.55M14.46 14.46l1.55 1.55M1.5 10h2.2M16.3 10h2.2M3.99 16.01l1.55-1.55M14.46 5.54l1.55-1.55'],
  audit: ['M6 4h11', 'M6 10h11', 'M6 16h11', 'M3 4h.01', 'M3 10h.01', 'M3 16h.01'],
  logout: ['M8 17H4a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h4', 'M13 14l4-4-4-4', 'M17 10H8'],
  theme: ['M10 2.5a7.5 7.5 0 1 0 0 15z', 'M10 2.5a7.5 7.5 0 0 1 0 15'],
  refresh: ['M16.5 10a6.5 6.5 0 1 1-1.9-4.6', 'M16.5 3.5v3h-3'],
  copy: ['M7 7h10v10H7z', 'M13 7V3H3v10h4'],
  external: ['M11 3h6v6', 'M17 3l-8 8', 'M15 12v4a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h4'],
  back: ['M12 15l-5-5 5-5'],
  search: ['M9 15a6 6 0 1 0 0-12 6 6 0 0 0 0 12z', 'M17 17l-3.5-3.5'],
};

export function icon(name, size = 18) {
  return s('svg', {
    class: 'icon', width: size, height: size, viewBox: '0 0 20 20', fill: 'none',
    stroke: 'currentColor', 'stroke-width': 1.6, 'stroke-linecap': 'round',
    'stroke-linejoin': 'round', 'aria-hidden': 'true', focusable: 'false',
  }, (ICONS[name] || []).map((d) => s('path', { d })));
}

// ----- Formatting -----

const numberFmt = new Intl.NumberFormat();
const compactFmt = new Intl.NumberFormat(undefined, { notation: 'compact', maximumFractionDigits: 1 });

export const fmtNum = (n) => numberFmt.format(n ?? 0);

/** "1 customer" / "3 customers" */
export const plural = (n, one, many = `${one}s`) => `${numberFmt.format(n ?? 0)} ${n === 1 ? one : many}`;
export const fmtCompact = (n) => (Math.abs(n) < 10000 ? numberFmt.format(n) : compactFmt.format(n));

export function fmtPct(part, total) {
  if (!total) return '0%';
  const p = (part / total) * 100;
  return `${p < 10 && p > 0 ? p.toFixed(1) : Math.round(p)}%`;
}

export function fmtDate(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
}

export function fmtDateTime(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' });
}

/** A YYYY-MM-DD (UTC) day as "Nov 25". */
export function fmtDay(day, opts = { month: 'short', day: 'numeric' }) {
  return new Date(`${day}T00:00:00Z`).toLocaleDateString(undefined, { ...opts, timeZone: 'UTC' });
}

const relFmt = new Intl.RelativeTimeFormat(undefined, { numeric: 'auto' });
export function fmtRelative(iso) {
  if (!iso) return '—';
  const secs = (new Date(iso).getTime() - Date.now()) / 1000;
  const abs = Math.abs(secs);
  const units = [['year', 31536000], ['month', 2592000], ['week', 604800], ['day', 86400], ['hour', 3600], ['minute', 60]];
  for (const [unit, size] of units) {
    if (abs >= size) return relFmt.format(Math.round(secs / size), unit);
  }
  return 'just now';
}

/** A date with its relative form in the tooltip-free secondary line. */
export function timeEl(iso, mode = 'relative') {
  if (!iso) return h('span', { class: 'muted' }, '—');
  return h('time', { datetime: iso, title: fmtDateTime(iso) }, mode === 'relative' ? fmtRelative(iso) : fmtDate(iso));
}

const ZERO_DECIMAL = new Set(['bif', 'clp', 'djf', 'gnf', 'jpy', 'kmf', 'krw', 'mga', 'pyg', 'rwf', 'ugx', 'vnd', 'vuv', 'xaf', 'xof', 'xpf']);
export function fmtMoney(minor, currency) {
  const cur = (currency || 'usd').toLowerCase();
  const amount = ZERO_DECIMAL.has(cur) ? minor : minor / 100;
  try {
    return new Intl.NumberFormat(undefined, { style: 'currency', currency: cur.toUpperCase() }).format(amount);
  } catch {
    return `${amount} ${cur.toUpperCase()}`;
  }
}

export const CHANNEL_LABELS = {
  web: 'Web (Stripe)',
  app_store: 'App Store',
  play_store: 'Google Play',
  mac_app_store: 'Mac App Store',
  amazon: 'Amazon',
  promotional: 'Promotional',
  stripe: 'Stripe (RevenueCat)',
};
export function channelLabel(channel) {
  if (!channel) return '—';
  return CHANNEL_LABELS[channel] || channel.replace(/_/g, ' ').replace(/^\w/, (c) => c.toUpperCase());
}
export const planLabel = (plan) => (plan === 'yearly' ? 'Yearly' : plan === 'monthly' ? 'Monthly' : plan || '—');

// ----- Building blocks -----

/** Status pill: a coloured dot + a text label (colour is never the only cue). */
export function badge(label, tone = 'neutral') {
  return h('span', { class: `badge badge-${tone}` }, h('span', { class: 'badge-dot', 'aria-hidden': 'true' }), label);
}

export function premiumBadge(premium) {
  if (!premium?.active) return badge('Free', 'neutral');
  const label = `${channelLabel(premium.channel)} · ${planLabel(premium.plan)}`;
  return premium.trial ? badge(`Trial · ${label}`, 'warning') : badge(label, 'good');
}

export function initials(name, email) {
  const src = (name || email || '?').trim();
  const parts = src.split(/[\s@._-]+/).filter(Boolean);
  return ((parts[0]?.[0] || '?') + (parts[1]?.[0] || '')).toUpperCase();
}

export function avatar(user, size = 'md') {
  const el = h('span', { class: `avatar avatar-${size}`, 'aria-hidden': 'true' }, initials(user.name, user.email));
  if (user.avatar_url && user.avatar_url.startsWith('/uploads/')) {
    const img = h('img', { src: user.avatar_url, alt: '', loading: 'lazy' });
    img.addEventListener('error', () => img.remove());
    el.append(img);
  }
  return el;
}

export function pageHeader(title, subtitle, ...actions) {
  return h('header', { class: 'page-header' },
    h('div', null, h('h1', null, title), subtitle ? h('p', { class: 'page-subtitle' }, subtitle) : null),
    actions.length ? h('div', { class: 'page-actions' }, actions) : null);
}

export function card(title, body, { subtitle, actions, className } = {}) {
  return h('section', { class: `card ${className || ''}` },
    title ? h('div', { class: 'card-head' },
      h('div', null, h('h2', null, title), subtitle ? h('p', { class: 'card-subtitle' }, subtitle) : null),
      actions || null) : null,
    h('div', { class: 'card-body' }, body));
}

/** Definition list from [[label, value], ...]; falsy rows are skipped. */
export function details(rows) {
  return h('dl', { class: 'details' }, rows.filter(Boolean).map(([label, value]) =>
    h('div', { class: 'details-row' }, h('dt', null, label), h('dd', null, value ?? '—'))));
}

export function statTile(label, value, sub, { tone, href } = {}) {
  const inner = [
    h('div', { class: 'stat-label' }, tone ? h('span', { class: `badge-dot dot-${tone}`, 'aria-hidden': 'true' }) : null, label),
    h('div', { class: 'stat-value' }, value),
    sub ? h('div', { class: 'stat-sub' }, sub) : null,
  ];
  return href ? h('a', { class: 'stat stat-link', href }, inner) : h('div', { class: 'stat' }, inner);
}

export function loading(label = 'Loading…') {
  return h('div', { class: 'loading', role: 'status' }, h('span', { class: 'spinner', 'aria-hidden': 'true' }), label);
}

export function emptyState(title, text) {
  return h('div', { class: 'empty' }, h('p', { class: 'empty-title' }, title), text ? h('p', null, text) : null);
}

export function errorState(err, onRetry) {
  return h('div', { class: 'callout callout-critical', role: 'alert' },
    h('p', null, h('strong', null, 'Something went wrong. '), err?.message || String(err)),
    onRetry ? h('button', { class: 'btn btn-sm', type: 'button', onclick: onRetry }, 'Try again') : null);
}

export function callout(tone, ...children) {
  return h('div', { class: `callout callout-${tone}` }, children);
}

export function externalLink(href, label) {
  return h('a', { href, target: '_blank', rel: 'noopener noreferrer', class: 'ext-link' }, label, icon('external', 14));
}

export function mono(text) {
  return h('code', { class: 'mono' }, text);
}

export function copyButton(text, label = 'Copy') {
  const btn = h('button', { class: 'btn btn-ghost btn-xs', type: 'button', title: `${label}: ${text}`, 'aria-label': `${label} ${text}` }, icon('copy', 14));
  btn.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(text);
      toast('Copied');
    } catch {
      toast('Couldn’t copy — select the text instead', 'critical');
    }
  });
  return btn;
}

/** Text value with a copy button. */
export function copyable(text) {
  if (!text) return h('span', { class: 'muted' }, '—');
  return h('span', { class: 'copyable' }, mono(text), copyButton(text));
}

// ----- Toasts -----

export function toast(message, tone = 'good') {
  const host = document.getElementById('toasts');
  if (!host) return;
  const el = h('div', { class: `toast toast-${tone}` }, h('span', { class: `badge-dot dot-${tone}`, 'aria-hidden': 'true' }), message);
  host.append(el);
  setTimeout(() => {
    el.classList.add('toast-out');
    setTimeout(() => el.remove(), 250);
  }, 3800);
}

// ----- Dialogs -----

/**
 * Modal confirmation. Resolves to {note} when confirmed, null when
 * cancelled. `requireText` makes the admin type a value (e.g. the
 * customer's e-mail) before the confirm button unlocks. `onConfirm` may
 * be async: the dialog stays open showing a spinner, and an error it
 * throws is shown inside the dialog so the admin can retry.
 */
export function confirmDialog({ title, body, confirmLabel = 'Confirm', tone = 'primary', requireText, noteLabel, onConfirm }) {
  return new Promise((resolve) => {
    const errorBox = h('div', { class: 'dialog-error', role: 'alert', hidden: true });
    const note = noteLabel ? h('textarea', { class: 'input', rows: 3, maxlength: 1000, id: 'dlg-note' }) : null;
    const typed = requireText ? h('input', {
      class: 'input', id: 'dlg-confirm', autocomplete: 'off', spellcheck: 'false',
      placeholder: requireText,
    }) : null;
    const confirmBtn = h('button', { class: `btn btn-${tone}`, type: 'submit', disabled: Boolean(requireText) }, confirmLabel);
    const cancelBtn = h('button', { class: 'btn', type: 'button' }, 'Cancel');
    if (typed) {
      typed.addEventListener('input', () => {
        confirmBtn.disabled = typed.value.trim().toLowerCase() !== requireText.trim().toLowerCase();
      });
    }

    const form = h('form', { class: 'dialog-form', novalidate: true },
      h('h2', { class: 'dialog-title' }, title),
      h('div', { class: 'dialog-body' }, body),
      typed ? h('div', { class: 'field' }, h('label', { for: 'dlg-confirm' }, 'Type ', h('strong', null, requireText), ' to confirm'), typed) : null,
      note ? h('div', { class: 'field' }, h('label', { for: 'dlg-note' }, noteLabel), note) : null,
      errorBox,
      h('div', { class: 'dialog-actions' }, cancelBtn, confirmBtn));
    const dialog = h('dialog', { class: 'dialog', 'aria-labelledby': 'dlg-title' }, form);
    form.querySelector('.dialog-title').id = 'dlg-title';

    let settled = false;
    // Navigating away (Back button, a link) closes the dialog as cancelled
    // so it can't linger over a different page.
    const onNavigate = () => finish(null);
    const finish = (value) => {
      if (settled) return;
      settled = true;
      window.removeEventListener('hashchange', onNavigate);
      dialog.close();
      dialog.remove();
      resolve(value);
    };
    window.addEventListener('hashchange', onNavigate);
    cancelBtn.addEventListener('click', () => finish(null));
    dialog.addEventListener('cancel', (e) => {
      e.preventDefault();
      if (!confirmBtn.classList.contains('is-busy')) finish(null);
    });
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      if (confirmBtn.disabled) return;
      const value = { note: note ? note.value.trim() : '' };
      if (!onConfirm) return finish(value);
      errorBox.hidden = true;
      confirmBtn.disabled = true;
      cancelBtn.disabled = true;
      confirmBtn.classList.add('is-busy');
      try {
        await onConfirm(value);
        finish(value);
      } catch (err) {
        errorBox.textContent = err?.message || String(err);
        errorBox.hidden = false;
        confirmBtn.disabled = false;
        cancelBtn.disabled = false;
        confirmBtn.classList.remove('is-busy');
      }
    });

    document.body.append(dialog);
    dialog.showModal();
    (typed || note || confirmBtn).focus();
  });
}

// ----- Theme -----

const THEME_KEY = 'lively-admin-theme';

export function initTheme() {
  let saved = null;
  try { saved = localStorage.getItem(THEME_KEY); } catch { /* storage blocked */ }
  if (saved === 'light' || saved === 'dark') document.documentElement.dataset.theme = saved;
}

export function toggleTheme() {
  const root = document.documentElement;
  const current = root.dataset.theme
    || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  const next = current === 'dark' ? 'light' : 'dark';
  root.dataset.theme = next;
  try { localStorage.setItem(THEME_KEY, next); } catch { /* storage blocked */ }
}

// ----- Misc -----

/** Replace the current hash without adding a history entry or re-rendering. */
export function replaceQuery(path, params) {
  const qs = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) if (v !== '' && v != null) qs.set(k, String(v));
  const str = qs.toString();
  history.replaceState(null, '', `#${path}${str ? `?${str}` : ''}`);
}

export function debounce(fn, ms) {
  let t;
  return (...args) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...args), ms);
  };
}
