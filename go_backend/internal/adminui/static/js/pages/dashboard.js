import {
  h, icon, pageHeader, card, statTile, loading, errorState, externalLink,
  fmtNum, fmtCompact, fmtPct, fmtDateTime, plural,
} from '../ui.js';
import { api } from '../api.js';
import { columnChart, lineChart, segmentedBar } from '../charts.js';

export const title = 'Dashboard';

export async function render(root, ctx) {
  const refresh = h('button', { class: 'btn btn-sm', type: 'button' }, icon('refresh', 16), 'Refresh');
  refresh.addEventListener('click', () => ctx.rerender());
  const body = h('div', { class: 'stack' }, loading());
  root.append(pageHeader('Dashboard', 'Customers, subscriptions and activity at a glance', refresh), body);

  let stats;
  try {
    stats = await api('/admin/stats');
  } catch (err) {
    if (ctx.isCurrent()) body.replaceChildren(errorState(err, () => ctx.rerender()));
    return;
  }
  if (!ctx.isCurrent()) return;
  const { users, premium, content } = stats;

  const kpis = h('div', { class: 'grid grid-4' },
    statTile('Customers', fmtCompact(users.total),
      `+${fmtNum(users.new_7d)} this week · +${fmtNum(users.new_1d)} today`, { href: '#/customers' }),
    statTile('Active this week', fmtCompact(users.active_7d),
      `${fmtNum(users.active_1d)} today · ${fmtNum(users.active_30d)} in 30 days`),
    statTile('Premium subscribers', fmtCompact(premium.total),
      `${fmtPct(premium.total, users.total)} of customers · ${fmtNum(premium.trialing)} on a trial`,
      { href: '#/customers?filter=premium' }),
    statTile('Open reports', fmtNum(content.open_reports),
      content.open_reports ? 'Apple and Google expect action within 24 hours' : 'Nothing waiting',
      { href: '#/moderation', tone: content.open_reports ? 'warning' : 'good' }));

  const charts = h('div', { class: 'grid grid-2' },
    card('Sign-ups per day', columnChart(stats.signups, { title: 'Sign-ups per day', unit: 'sign-ups' }),
      { subtitle: 'New accounts, last 30 days (UTC)' }),
    card('Active customers per day', lineChart(stats.active_users, { title: 'Active customers per day', unit: 'active customers' }),
      { subtitle: 'Customers who opened the app, last 30 days (UTC)' }));

  const channels = [
    { key: 'web', label: 'Web (Stripe)', value: premium.stripe, slot: 1 },
    { key: 'app_store', label: 'App Store', value: premium.app_store, slot: 2 },
    { key: 'play_store', label: 'Google Play', value: premium.play_store, slot: 3 },
    { key: 'other', label: 'Other stores', value: premium.other_store, slot: 4 },
  ];
  const premiumCard = card('Premium subscribers by channel',
    h('div', { class: 'stack' },
      segmentedBar(channels, { unit: 'subscribers', emptyText: 'No premium subscribers yet.' }),
      h('div', { class: 'grid grid-5 stats-compact' },
        statTile('Monthly plan', fmtNum(premium.monthly)),
        statTile('Yearly plan', fmtNum(premium.yearly)),
        statTile('On a free trial', fmtNum(premium.trialing)),
        statTile('Won’t renew', fmtNum(premium.cancelling), 'Cancelled, still active until the period ends'),
        statTile('Billing problems', fmtNum(premium.billing_issues), 'Store couldn’t charge the card',
          { tone: premium.billing_issues ? 'warning' : undefined })),
      h('p', { class: 'muted small' },
        'Revenue and payouts are in ', externalLink('https://dashboard.stripe.com/', 'Stripe'),
        ' for web checkout and ', externalLink('https://app.revenuecat.com/', 'RevenueCat'),
        ' for the App Store and Google Play.')),
    { subtitle: 'Each subscriber is counted once, under the channel that currently gives them premium' });

  const usage = card('Usage',
    h('div', { class: 'grid grid-4 stats-compact' },
      statTile('AI messages', fmtNum(content.ai_messages_7d), 'Sent to the astrologer, last 7 days'),
      statTile('Journal entries', fmtNum(content.journal_entries_7d), 'Last 7 days'),
      statTile('Compatibility reports', fmtNum(content.compatibility_reports_7d), 'Last 7 days'),
      statTile('Finished onboarding', fmtPct(users.onboarded, users.total), `${plural(users.onboarded, 'customer')} saved a birth profile`),
      statTile('New posts', fmtNum(content.posts_7d), `Last 7 days · ${fmtNum(content.posts)} in total`),
      statTile('New comments', fmtNum(content.comments_7d), `Last 7 days · ${fmtNum(content.comments)} in total`),
      statTile('Spaces', fmtNum(content.spaces), 'Community spaces'),
      statTile('Banned accounts', fmtNum(users.banned), null, { href: '#/customers?filter=banned' })));

  body.replaceChildren(kpis, charts, premiumCard, usage,
    h('p', { class: 'muted small' }, `Updated ${fmtDateTime(stats.generated_at)}`));
}
