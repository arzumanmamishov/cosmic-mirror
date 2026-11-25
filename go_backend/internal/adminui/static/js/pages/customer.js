import {
  h, icon, card, details, loading, errorState, avatar, badge, premiumBadge, statTile,
  timeEl, fmtDate, fmtDateTime, fmtNum, copyable, mono, externalLink, confirmDialog, toast,
  channelLabel, planLabel, plural,
} from '../ui.js';
import { api } from '../api.js';
import { describeAudit, actionLabel } from './audit.js';

export const title = 'Customer';

export async function render(root, ctx) {
  const [id] = ctx.params;
  root.append(h('a', { href: '#/customers', class: 'back-link' }, icon('back', 16), 'Customers'));
  const body = h('div', null, loading());
  root.append(body);

  let user;
  let history = [];
  try {
    [user, history] = await Promise.all([
      api(`/admin/users/${id}`),
      api('/admin/audit', { query: { target_id: id, limit: 20 } }).then((r) => r.entries).catch(() => []),
    ]);
  } catch (err) {
    if (!ctx.isCurrent()) return;
    body.replaceChildren(err.status === 404
      ? h('div', { class: 'empty' }, h('p', { class: 'empty-title' }, 'Customer not found'),
        h('p', null, 'The account may have been deleted.'))
      : errorState(err, () => ctx.rerender()));
    return;
  }
  if (!ctx.isCurrent()) return;
  document.title = `${user.name || user.email} · Lively Admin`;
  body.replaceChildren(header(user, ctx), h('div', { class: 'grid grid-2 align-start' },
    h('div', { class: 'stack' }, accountCard(user), activityCard(user)),
    h('div', { class: 'stack' }, subscriptionCard(user), historyCard(history))));
}

function header(user, ctx) {
  const actions = [];
  if (user.is_admin) {
    actions.push(h('span', { class: 'muted small' }, 'Admin accounts can’t be banned or deleted here.'));
  } else {
    const banBtn = user.banned_at
      ? h('button', { class: 'btn', type: 'button' }, 'Unban')
      : h('button', { class: 'btn', type: 'button' }, 'Ban');
    banBtn.addEventListener('click', () => (user.banned_at ? unban(user, ctx) : ban(user, ctx)));
    const del = h('button', { class: 'btn btn-danger', type: 'button' }, 'Delete account');
    del.addEventListener('click', () => remove(user, ctx));
    actions.push(banBtn, del);
  }
  return h('header', { class: 'page-header profile-header' },
    h('div', { class: 'person person-lg' }, avatar(user, 'lg'),
      h('div', { class: 'person-text' },
        h('h1', null, user.name || user.email),
        user.name ? h('span', { class: 'person-sub' }, user.email) : null,
        h('div', { class: 'badges' },
          premiumBadge(user.premium),
          user.banned_at ? badge(`Banned ${fmtDate(user.banned_at)}`, 'critical') : null,
          user.is_admin ? badge('Admin', 'info') : null))),
    h('div', { class: 'page-actions' }, actions));
}

function accountCard(u) {
  const a = u.activity;
  return card('Account', details([
    ['User ID', copyable(u.id)],
    ['E-mail', copyable(u.email)],
    ['E-mail verified', u.email_verified_at ? fmtDate(u.email_verified_at) : h('span', { class: 'muted' }, 'Not verified')],
    ['Joined', fmtDateTime(u.created_at)],
    ['Last signed in', timeEl(u.last_login_at)],
    ['Last opened the app', timeEl(u.last_seen_at)],
    ['Signed-in devices', fmtNum(a.active_sessions)],
    ['Onboarding', a.onboarded ? 'Finished (birth profile saved)' : h('span', { class: 'muted' }, 'Not finished')],
    u.banned_at && ['Banned', fmtDateTime(u.banned_at)],
  ]));
}

function stripeLink(mode, kind, id) {
  if (!id) return null;
  const base = mode === 'test' ? 'https://dashboard.stripe.com/test' : 'https://dashboard.stripe.com';
  return externalLink(`${base}/${kind}/${encodeURIComponent(id)}`, 'Open in Stripe');
}

function subscriptionCard(u) {
  const p = u.premium;
  const sub = u.subscription;
  const summary = p.active
    ? details([
      ['Premium', h('span', null, `Yes, through ${channelLabel(p.channel)}`)],
      ['Plan', planLabel(p.plan)],
      ['Free trial', p.trial ? 'Yes, in the trial now' : 'No'],
      [p.will_renew ? 'Renews' : 'Ends', p.expires_at ? fmtDate(p.expires_at) : 'No end date'],
      ['Auto-renew', p.will_renew ? 'On' : 'Off (cancelled)'],
    ])
    : details([['Premium', 'No, on the free plan']]);

  const parts = [summary];
  if (sub && (sub.stripe_customer_id || sub.stripe_subscription_id)) {
    parts.push(h('h3', { class: 'subhead' }, 'Web (Stripe)'), details([
      ['Status', sub.stripe_status || '—'],
      ['Plan', planLabel(sub.stripe_plan)],
      ['Price', sub.stripe_price_id ? mono(sub.stripe_price_id) : '—'],
      ['Current period ends', fmtDate(sub.stripe_current_period_end)],
      ['Cancels at period end', sub.stripe_cancel_at_period_end ? 'Yes' : 'No'],
      sub.stripe_trial_end_at && ['Trial ends', fmtDate(sub.stripe_trial_end_at)],
      ['Customer', sub.stripe_customer_id
        ? h('span', { class: 'copyable' }, copyable(sub.stripe_customer_id), stripeLink(u.stripe_mode, 'customers', sub.stripe_customer_id))
        : '—'],
      ['Subscription', sub.stripe_subscription_id
        ? h('span', { class: 'copyable' }, copyable(sub.stripe_subscription_id), stripeLink(u.stripe_mode, 'subscriptions', sub.stripe_subscription_id))
        : '—'],
    ]));
  }
  if (sub && (sub.store_status || sub.store_product_id)) {
    parts.push(h('h3', { class: 'subhead' }, 'App Store / Google Play'), details([
      ['Store', channelLabel((sub.store || '').toLowerCase())],
      ['Status', sub.store_status || '—'],
      ['Product', sub.store_product_id ? mono(sub.store_product_id) : '—'],
      ['Expires', fmtDate(sub.store_expires_at)],
      ['Free trial', sub.store_is_trial ? 'Yes' : 'No'],
      ['Will renew', sub.store_will_renew ? 'Yes' : 'No'],
      ['Billing problem', sub.store_billing_issue ? badge('Card couldn’t be charged', 'warning') : 'No'],
      ['Last update from RevenueCat', fmtDateTime(sub.store_updated_at)],
      ['RevenueCat app user ID', copyable(sub.revenuecat_app_user_id)],
    ]));
  }
  if (sub) {
    parts.push(h('p', { class: 'muted small' }, sub.trial_consumed
      ? 'Has already used a free trial, so the web checkout won’t offer another.'
      : 'Hasn’t used a free trial yet.'));
  }
  return card('Subscription', h('div', { class: 'stack-sm' }, parts));
}

function activityCard(u) {
  const a = u.activity;
  return card('Activity', h('div', { class: 'grid grid-3 stats-compact' },
    statTile('AI conversations', fmtNum(a.ai_threads), `${plural(a.ai_messages, 'message')} sent`),
    statTile('Journal entries', fmtNum(a.journal_entries)),
    statTile('Saved people', fmtNum(a.saved_people), plural(a.compatibility_reports, 'compatibility report')),
    statTile('Posts', fmtNum(a.posts), plural(a.comments, 'comment')),
    statTile('Spaces created', fmtNum(a.spaces_created)),
    statTile('Reports against them', fmtNum(a.reports_against),
      `${a.open_reports_against ? `${fmtNum(a.open_reports_against)} still open · ` : ''}they filed ${fmtNum(a.reports_filed)}`,
      { tone: a.open_reports_against ? 'warning' : undefined })));
}

function historyCard(entries) {
  const body = entries.length
    ? h('ul', { class: 'timeline' }, entries.map((e) => h('li', null,
      h('div', { class: 'timeline-head' }, h('strong', null, actionLabel(e.action)), h('span', { class: 'muted' }, ` by ${e.admin_email}`)),
      h('div', { class: 'muted small' }, fmtDateTime(e.created_at)),
      describeAudit(e) ? h('div', { class: 'small' }, describeAudit(e)) : null)))
    : h('p', { class: 'muted' }, 'No admin actions on this account yet.');
  return card('Admin history', body);
}

// ----- Actions -----

async function ban(u, ctx) {
  const done = await confirmDialog({
    title: `Ban ${u.email}?`,
    body: h('ul', { class: 'bullets' },
      h('li', null, 'They’re signed out on every device and can’t sign back in. The app tells them the account is suspended.'),
      h('li', null, 'Their posts, comments and spaces are hidden from everyone.'),
      h('li', null, 'Their subscription isn’t touched. Refund or cancel it separately if needed.'),
      h('li', null, 'You can unban them later.')),
    confirmLabel: 'Ban customer',
    tone: 'danger',
    noteLabel: 'Reason (optional, only admins see it)',
    onConfirm: ({ note }) => api(`/admin/users/${u.id}/ban`, { method: 'POST', body: { note } }),
  });
  if (done) {
    toast(`${u.email} is banned`);
    ctx.rerender();
  }
}

async function unban(u, ctx) {
  const done = await confirmDialog({
    title: `Unban ${u.email}?`,
    body: h('p', null, 'They can sign in again, and their posts and comments become visible again.'),
    confirmLabel: 'Unban customer',
    noteLabel: 'Reason (optional, only admins see it)',
    onConfirm: ({ note }) => api(`/admin/users/${u.id}/unban`, { method: 'POST', body: { note } }),
  });
  if (done) {
    toast(`${u.email} is unbanned`);
    ctx.rerender();
  }
}

async function remove(u, ctx) {
  const storeSub = u.premium.active && u.premium.channel !== 'web';
  const done = await confirmDialog({
    title: `Delete ${u.email}?`,
    body: h('div', { class: 'stack-sm' },
      h('p', null, 'This is the same as the customer deleting their account in the app:'),
      h('ul', { class: 'bullets' },
        h('li', null, 'A web (Stripe) subscription is cancelled right away, with no refund.'),
        h('li', null, 'They’re signed out on every device.'),
        h('li', null, 'The account disappears now, and all its data is erased for good after 30 days.')),
      storeSub ? h('div', { class: 'callout callout-warning' },
        h('strong', null, `They pay through ${channelLabel(u.premium.channel)}. `),
        'Apple and Google keep charging until the customer cancels in their store settings. Tell them to cancel there.') : null),
    confirmLabel: 'Delete account',
    tone: 'danger',
    requireText: u.email,
    noteLabel: 'Reason (optional, only admins see it)',
    onConfirm: ({ note }) => api(`/admin/users/${u.id}/delete`, { method: 'POST', body: { confirm_email: u.email, note } }),
  });
  if (done) {
    toast(`${u.email} was deleted`);
    ctx.navigate('#/customers');
  }
}
