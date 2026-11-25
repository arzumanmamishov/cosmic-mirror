import { h, pageHeader, loading, errorState, emptyState, fmtDateTime, mono, channelLabel } from '../ui.js';
import { api } from '../api.js';

export const title = 'Audit log';

const PAGE_SIZE = 50;

const ACTIONS = {
  'user.ban': 'Banned a customer',
  'user.unban': 'Unbanned a customer',
  'user.delete': 'Deleted a customer',
  'settings.stripe.update': 'Changed Stripe settings',
  'report.resolve': 'Resolved a report',
};

const REPORT_ACTIONS = {
  dismiss: 'Dismissed',
  hide: 'Hid',
  delete: 'Deleted',
  ban_user: 'Banned the author of',
};

export const actionLabel = (action) => ACTIONS[action] || action;

function settingValue(v, fallback) {
  return v === '' || v === null || v === undefined ? fallback : String(v);
}

/** One-line human summary of an audit entry's details. */
export function describeAudit(e) {
  const d = e.details || {};
  const note = d.note ? `Note: “${d.note}”` : '';
  const join = (...parts) => parts.filter(Boolean).join(' · ');
  switch (e.action) {
    case 'user.ban':
    case 'user.unban':
      return join(d.email, note);
    case 'user.delete':
      return join(d.email, d.premium_channel ? `was premium via ${channelLabel(d.premium_channel)}` : '', note);
    case 'settings.stripe.update': {
      const before = d.before || {};
      const after = d.after || {};
      const changes = [];
      const fields = [
        ['price_monthly', 'Monthly price', 'server default'],
        ['price_yearly', 'Yearly price', 'server default'],
        ['yearly_trial_days', 'Yearly trial days', 'server default'],
      ];
      for (const [key, label, fallback] of fields) {
        const a = settingValue(before[key], fallback);
        const b = settingValue(after[key], fallback);
        if (a !== b) changes.push(`${label}: ${a} → ${b}`);
      }
      return changes.length ? changes.join('; ') : 'Saved without changes';
    }
    case 'report.resolve':
      return join(`${REPORT_ACTIONS[d.action] || d.action} a ${d.target_type || 'item'}${d.reason ? ` reported for ${d.reason.replace(/_/g, ' ')}` : ''}`, note);
    default:
      return Object.keys(d).length ? JSON.stringify(d) : '';
  }
}

function targetCell(e) {
  if (e.target_type === 'user' && e.target_id) {
    return h('a', { href: `#/customers/${e.target_id}` }, e.details?.email || 'Customer');
  }
  if (e.target_type === 'setting') return `Setting: ${e.target_id}`;
  if (e.target_type === 'report') return h('span', null, 'Report ', mono(e.target_id.slice(0, 8)));
  return e.target_id ? `${e.target_type} ${e.target_id}` : '—';
}

export async function render(root, ctx) {
  root.append(pageHeader('Audit log', 'Every change made in the admin panel, newest first'));
  const body = h('div', null, loading());
  root.append(body);

  const rows = [];
  let offset = 0;
  const tbody = h('tbody');
  const more = h('button', { class: 'btn btn-sm', type: 'button' }, 'Load more');
  const pager = h('div', { class: 'pager center' }, more);

  async function loadPage() {
    more.disabled = true;
    let data;
    try {
      data = await api('/admin/audit', { query: { limit: PAGE_SIZE, offset } });
    } catch (err) {
      if (!ctx.isCurrent()) return;
      if (!rows.length) body.replaceChildren(errorState(err, () => ctx.rerender()));
      else more.disabled = false;
      return;
    }
    if (!ctx.isCurrent()) return;
    const entries = data.entries || [];
    offset += entries.length;
    for (const e of entries) {
      rows.push(e);
      tbody.append(h('tr', null,
        h('td', { class: 'nowrap' }, fmtDateTime(e.created_at)),
        h('td', null, e.admin_email),
        h('td', null, actionLabel(e.action)),
        h('td', null, targetCell(e)),
        h('td', { class: 'wrap' }, describeAudit(e))));
    }
    if (!rows.length) {
      body.replaceChildren(emptyState('Nothing here yet', 'Bans, deletions, settings changes and report decisions appear here.'));
      return;
    }
    if (body.firstElementChild?.classList.contains('loading')) {
      body.replaceChildren(h('div', { class: 'card' },
        h('div', { class: 'table-scroll' },
          h('table', { class: 'table' },
            h('thead', null, h('tr', null, h('th', null, 'When'), h('th', null, 'Admin'), h('th', null, 'Action'), h('th', null, 'Target'), h('th', null, 'Details'))),
            tbody)),
        pager));
    }
    pager.hidden = entries.length < PAGE_SIZE;
    more.disabled = false;
  }
  more.addEventListener('click', loadPage);
  await loadPage();
}
