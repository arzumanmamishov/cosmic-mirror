import {
  h, icon, pageHeader, loading, errorState, emptyState, avatar, badge, premiumBadge,
  timeEl, fmtDate, fmtNum, debounce, replaceQuery,
} from '../ui.js';
import { api } from '../api.js';

export const title = 'Customers';

const PAGE_SIZE = 50;

const FILTERS = [
  ['all', 'All customers'],
  ['premium', 'Premium'],
  ['free', 'Free'],
  ['trial', 'On a free trial'],
  ['web', 'Premium · Web (Stripe)'],
  ['app_store', 'Premium · App Store'],
  ['play_store', 'Premium · Google Play'],
  ['banned', 'Banned'],
];

export async function render(root, ctx) {
  const state = {
    q: ctx.query.get('q') || '',
    filter: FILTERS.some(([v]) => v === ctx.query.get('filter')) ? ctx.query.get('filter') : 'all',
    page: Math.max(1, parseInt(ctx.query.get('page') || '1', 10) || 1),
  };

  const subtitle = h('p', { class: 'page-subtitle' }, ' ');
  const header = pageHeader('Customers');
  header.firstElementChild.append(subtitle);

  const search = h('input', {
    class: 'input', type: 'search', id: 'customer-search', value: state.q,
    placeholder: 'Search by e-mail, name, user ID or Stripe customer ID', 'aria-label': 'Search customers',
  });
  const filter = h('select', { class: 'input select', 'aria-label': 'Filter customers' },
    FILTERS.map(([value, label]) => h('option', { value, selected: value === state.filter }, label)));
  const toolbar = h('div', { class: 'toolbar' },
    h('div', { class: 'search' }, icon('search', 16), search), filter);

  const results = h('div', null, loading());
  root.append(header, toolbar, results);

  let seq = 0;
  async function load() {
    const mine = ++seq;
    replaceQuery('/customers', { q: state.q, filter: state.filter === 'all' ? '' : state.filter, page: state.page > 1 ? state.page : '' });
    results.replaceChildren(loading());
    let data;
    try {
      data = await api('/admin/users', {
        query: { q: state.q, filter: state.filter, limit: PAGE_SIZE, offset: (state.page - 1) * PAGE_SIZE },
      });
    } catch (err) {
      if (mine === seq && ctx.isCurrent()) results.replaceChildren(errorState(err, load));
      return;
    }
    if (mine !== seq || !ctx.isCurrent()) return;
    subtitle.textContent = `${fmtNum(data.total)} ${data.total === 1 ? 'customer' : 'customers'}${state.q || state.filter !== 'all' ? ' match' : ''}`;
    results.replaceChildren(renderTable(data));
  }

  function renderTable({ users, total, offset }) {
    if (!users.length) {
      return state.q || state.filter !== 'all'
        ? emptyState('No customers match', 'Try a different search or filter.')
        : emptyState('No customers yet', 'People who sign up in the app appear here.');
    }
    const rows = users.map((u) => {
      const href = `#/customers/${u.id}`;
      const tr = h('tr', { class: 'row-link' },
        h('td', null, h('div', { class: 'person' }, avatar(u),
          h('div', { class: 'person-text' },
            h('a', { href, class: 'person-name' }, u.name || u.email),
            u.name ? h('span', { class: 'person-sub' }, u.email) : null))),
        h('td', null, h('div', { class: 'badges' }, premiumBadge(u.premium), u.banned_at ? badge('Banned', 'critical') : null)),
        h('td', { class: 'nowrap' }, h('time', { datetime: u.created_at, title: fmtDate(u.created_at) }, fmtDate(u.created_at))),
        h('td', { class: 'nowrap' }, timeEl(u.last_seen_at || u.last_login_at)));
      tr.addEventListener('click', (e) => {
        if (e.target.closest('a')) return;
        ctx.navigate(href);
      });
      return tr;
    });
    const from = offset + 1;
    const to = offset + users.length;
    const prev = h('button', { class: 'btn btn-sm', type: 'button', disabled: state.page <= 1 }, 'Previous');
    const next = h('button', { class: 'btn btn-sm', type: 'button', disabled: to >= total }, 'Next');
    prev.addEventListener('click', () => { state.page -= 1; load(); });
    next.addEventListener('click', () => { state.page += 1; load(); });
    return h('div', { class: 'card' },
      h('div', { class: 'table-scroll' },
        h('table', { class: 'table' },
          h('thead', null, h('tr', null,
            h('th', null, 'Customer'), h('th', null, 'Plan'), h('th', null, 'Joined'), h('th', null, 'Last active'))),
          h('tbody', null, rows))),
      h('div', { class: 'pager' },
        h('span', { class: 'muted' }, `${fmtNum(from)}–${fmtNum(to)} of ${fmtNum(total)}`),
        h('div', { class: 'pager-buttons' }, prev, next)));
  }

  search.addEventListener('input', debounce(() => {
    state.q = search.value.trim();
    state.page = 1;
    load();
  }, 350));
  filter.addEventListener('change', () => {
    state.filter = filter.value;
    state.page = 1;
    load();
  });

  await load();
}
