import {
  h, pageHeader, loading, errorState, emptyState, badge, timeEl, fmtDateTime, fmtNum,
  confirmDialog, toast, replaceQuery,
} from '../ui.js';
import { api } from '../api.js';

export const title = 'Moderation';

const PAGE_SIZE = 50;

const TABS = [
  ['open', 'Open'],
  ['actioned', 'Actioned'],
  ['dismissed', 'Dismissed'],
];

const REASONS = {
  spam: 'Spam',
  harassment: 'Harassment',
  hate: 'Hate speech',
  sexual: 'Sexual content',
  violence: 'Violence',
  self_harm: 'Self-harm',
  misinformation: 'Misinformation',
  other: 'Other',
};

const TARGETS = { post: 'Post', comment: 'Comment', space: 'Space', user: 'Profile' };

function actionsFor(report) {
  const t = report.target_type;
  const noun = (TARGETS[t] || t).toLowerCase();
  const list = [{
    action: 'dismiss', label: 'Dismiss', tone: 'primary',
    title: 'Dismiss this report?',
    text: `No rule was broken. Closes every open report on this ${noun}${t === 'post' || t === 'comment' ? ' and shows it again if it was auto-hidden' : ''}.`,
  }];
  if (t === 'post' || t === 'comment') {
    list.push({ action: 'hide', label: 'Hide', tone: 'primary', title: `Hide this ${noun}?`, text: `Hides the ${noun} from everyone except its author, and closes every open report on it.` });
  }
  if (t !== 'user') {
    list.push({ action: 'delete', label: 'Delete', tone: 'danger', title: `Delete this ${noun}?`, text: `Deletes the ${noun} for good and closes every open report on it.` });
  }
  if (report.target_owner_id) {
    list.push({
      action: 'ban_user', label: t === 'user' ? 'Ban user' : 'Ban author', tone: 'danger',
      title: t === 'user' ? 'Ban this user?' : `Ban the author of this ${noun}?`,
      text: 'They’re signed out everywhere and can’t sign back in, and all their posts and comments are hidden. Closes every open report on this item.',
    });
  }
  return list;
}

export async function render(root, ctx) {
  const status = TABS.some(([v]) => v === ctx.query.get('status')) ? ctx.query.get('status') : 'open';
  const tabs = h('div', { class: 'tabs', role: 'tablist' }, TABS.map(([value, label]) => {
    const a = h('a', { href: `#/moderation${value === 'open' ? '' : `?status=${value}`}`, class: 'tab', role: 'tab', 'aria-selected': String(value === status) }, label);
    return a;
  }));
  root.append(
    pageHeader('Moderation', 'Reports from the community. Apple and Google expect a decision within 24 hours.'),
    tabs);
  const list = h('div', { class: 'stack' }, loading());
  const more = h('button', { class: 'btn btn-sm', type: 'button', hidden: true }, 'Load more');
  root.append(list, h('div', { class: 'center' }, more));
  replaceQuery('/moderation', { status: status === 'open' ? '' : status });

  let offset = 0;
  let count = 0;
  async function loadPage() {
    more.disabled = true;
    let data;
    try {
      data = await api('/admin/reports', { query: { status, limit: PAGE_SIZE, offset } });
    } catch (err) {
      if (!ctx.isCurrent()) return;
      if (!count) list.replaceChildren(errorState(err, () => ctx.rerender()));
      more.disabled = false;
      return;
    }
    if (!ctx.isCurrent()) return;
    const reports = data.reports || [];
    if (!offset) list.replaceChildren();
    offset += reports.length;
    count += reports.length;
    for (const r of reports) list.append(reportCard(r, status, ctx));
    if (!count) {
      list.replaceChildren(status === 'open'
        ? emptyState('All clear', 'There are no open reports.')
        : emptyState('Nothing here yet', `Reports you ${status === 'dismissed' ? 'dismiss' : 'act on'} appear here.`));
    }
    more.hidden = reports.length < PAGE_SIZE;
    more.disabled = false;
  }
  more.addEventListener('click', loadPage);
  await loadPage();
}

function reportCard(r, status, ctx) {
  const target = TARGETS[r.target_type] || r.target_type;
  const head = h('div', { class: 'report-head' },
    h('div', { class: 'badges' },
      badge(target, 'neutral'),
      h('strong', null, REASONS[r.reason] || r.reason),
      r.open_report_count > 1 ? badge(`${fmtNum(r.open_report_count)} open reports`, 'warning') : null,
      r.target_hidden ? badge('Hidden', 'neutral') : null),
    h('span', { class: 'muted small' }, 'Reported ', timeEl(r.created_at)));

  const content = r.target_snippet
    ? h('blockquote', { class: 'snippet' }, r.target_snippet)
    : h('p', { class: 'muted' }, `This ${target.toLowerCase()} no longer exists.`);

  const meta = h('div', { class: 'report-meta small' },
    h('span', null, 'Reported by ', h('strong', null, r.reporter_email || 'a deleted account')),
    r.target_owner_id ? h('a', { href: `#/customers/${r.target_owner_id}` }, r.target_type === 'user' ? 'View this user' : 'View the author') : null);

  const parts = [head, content];
  if (r.details) parts.push(h('p', { class: 'report-details' }, h('span', { class: 'muted' }, 'Reporter’s note: '), r.details));
  parts.push(meta);

  if (status === 'open') {
    parts.push(h('div', { class: 'report-actions' }, actionsFor(r).map((a) => {
      const btn = h('button', { class: `btn btn-sm${a.tone === 'danger' ? ' btn-danger-outline' : ''}`, type: 'button' }, a.label);
      btn.addEventListener('click', async () => {
        const done = await confirmDialog({
          title: a.title,
          body: h('p', null, a.text),
          confirmLabel: a.label,
          tone: a.tone,
          noteLabel: 'Note (optional, only admins see it)',
          onConfirm: ({ note }) => api(`/admin/reports/${r.id}/resolve`, {
            method: 'POST', body: { action: a.action, note: note || null },
          }),
        });
        if (done) {
          toast('Report resolved');
          ctx.rerender();
        }
      });
      return btn;
    })));
  } else {
    parts.push(h('p', { class: 'muted small' },
      `${status === 'dismissed' ? 'Dismissed' : 'Actioned'} ${fmtDateTime(r.reviewed_at)}`,
      r.reviewed_note ? ` · “${r.reviewed_note}”` : ''));
  }
  return h('article', { class: 'card report' }, h('div', { class: 'card-body stack-sm' }, parts));
}
