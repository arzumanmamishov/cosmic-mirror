import {
  h, pageHeader, card, details, loading, errorState, badge, callout, copyable, mono,
  fmtMoney, fmtDateTime, externalLink, toast, confirmDialog,
} from '../ui.js';
import { api } from '../api.js';

export const title = 'Settings';

const CUSTOM = '__custom__';

export async function render(root, ctx) {
  root.append(pageHeader('Settings', 'Stripe web checkout, admin access and moderation'));
  const body = h('div', { class: 'stack' }, loading());
  root.append(body);

  let settings;
  try {
    settings = await api('/admin/settings');
  } catch (err) {
    if (ctx.isCurrent()) body.replaceChildren(errorState(err, () => ctx.rerender()));
    return;
  }
  // The price picker is a convenience: without it the admin can still
  // paste price IDs.
  let prices = null;
  let pricesError = null;
  if (settings.stripe.status.secret_key_set) {
    try {
      prices = (await api('/admin/stripe/prices')).prices || [];
    } catch (err) {
      pricesError = err;
    }
  }
  if (!ctx.isCurrent()) return;

  body.replaceChildren(
    stripeConnectionCard(settings.stripe.status),
    pricingCard(settings.stripe, prices, pricesError, ctx),
    h('div', { class: 'grid grid-2 align-start' },
      adminsCard(settings.admins),
      moderationCard(settings.moderation)));
}

// ----- Stripe connection (read-only: secrets stay on the server) -----

function stripeConnectionCard(st) {
  const modeBadge = !st.secret_key_set
    ? badge('Not connected', 'critical')
    : st.mode === 'live' ? badge('Live mode', 'good')
      : st.mode === 'test' ? badge('Test mode', 'warning') : badge('Unknown key type', 'warning');
  const webhookURL = `${location.origin}/api/v1/stripe/webhook`;
  return card('Stripe connection', h('div', { class: 'stack-sm' },
    details([
      ['Mode', modeBadge],
      ['Secret key', st.secret_key_set ? mono(st.secret_key_hint) : h('span', { class: 'muted' }, 'Not set')],
      ['Publishable key', st.publishable_key ? copyable(st.publishable_key) : h('span', { class: 'muted' }, 'Not set')],
      ['Webhook signing secret', st.webhook_secret_set ? 'Set' : h('span', { class: 'muted' }, 'Not set')],
      ['Webhook endpoint', copyable(webhookURL)],
      ['Web checkout', st.checkout_ready
        ? badge('Ready', 'good')
        : badge('Not ready: needs the keys and at least one price', 'warning')],
    ]),
    callout('neutral',
      h('strong', null, 'API keys can’t be changed here. '),
      'They’re secrets, so they never reach the browser. To change them, edit ',
      mono('STRIPE_SECRET_KEY'), ', ', mono('STRIPE_PUBLISHABLE_KEY'), ' and ', mono('STRIPE_WEBHOOK_SECRET'),
      ' in ', mono('.env.production'), ' on the server, then run ', mono('make prod-up'),
      '. In Stripe, send the webhook to the endpoint above.')),
  { subtitle: 'Stripe is only used for web checkout. The apps sell through the App Store and Google Play.', actions: externalLink('https://dashboard.stripe.com/', 'Stripe dashboard') });
}

// ----- Prices and trial (editable) -----

function priceLabel(p) {
  const every = p.interval_count === 1 ? `/${p.interval}` : ` every ${p.interval_count} ${p.interval}s`;
  const name = [p.product_name, p.nickname].filter(Boolean).join(' · ');
  return `${fmtMoney(p.unit_amount, p.currency)}${every}${name ? ` · ${name}` : ''} (${p.id})`;
}

/**
 * A price picker for one plan: a select of matching Stripe prices plus
 * "server default" and "enter an ID" options, or a plain text field when
 * the price list isn't available. Returns {el, value()}.
 */
function pricePicker(id, label, interval, current, fallback, prices) {
  const fallbackText = fallback ? `Server default (${fallback})` : 'Server default (not set)';
  const help = h('p', { class: 'field-help' });

  if (!prices) {
    const input = h('input', { class: 'input mono-input', id, value: current, placeholder: fallback || 'price_…', spellcheck: 'false', autocomplete: 'off' });
    help.textContent = `Paste a Stripe price ID. Leave empty to use the ${fallbackText.toLowerCase()}.`;
    return { el: h('div', { class: 'field' }, h('label', { for: id }, label), input, help), value: () => input.value.trim() };
  }

  const matching = prices.filter((p) => p.interval === interval && p.interval_count === 1);
  const select = h('select', { class: 'input select', id });
  select.append(h('option', { value: '' }, fallbackText));
  for (const p of matching) select.append(h('option', { value: p.id }, priceLabel(p)));
  if (current && !matching.some((p) => p.id === current)) {
    select.append(h('option', { value: current }, `${current} (saved, not found as an active ${interval}ly price)`));
  }
  select.append(h('option', { value: CUSTOM }, 'Enter a price ID…'));
  select.value = current || '';

  const custom = h('input', { class: 'input mono-input', placeholder: 'price_…', spellcheck: 'false', autocomplete: 'off', 'aria-label': `${label} ID`, hidden: true });
  const sync = () => {
    custom.hidden = select.value !== CUSTOM;
    if (!custom.hidden) custom.focus();
  };
  select.addEventListener('change', sync);
  help.textContent = matching.length
    ? `Active prices in Stripe that bill every ${interval}.`
    : `No active prices in Stripe bill every ${interval}. Create one in the Stripe dashboard (Product catalogue), then reload this page.`;
  return {
    el: h('div', { class: 'field' }, h('label', { for: id }, label), select, custom, help),
    // null = "Enter a price ID…" chosen but left empty.
    value: () => (select.value === CUSTOM ? custom.value.trim() || null : select.value),
  };
}

function pricingCard(stripe, prices, pricesError, ctx) {
  const { override, defaults, effective } = stripe;
  const monthly = pricePicker('price-monthly', 'Monthly plan price', 'month', override.price_monthly, defaults.price_monthly, prices);
  const yearly = pricePicker('price-yearly', 'Yearly plan price', 'year', override.price_yearly, defaults.price_yearly, prices);
  const trial = h('input', {
    class: 'input input-narrow', id: 'trial-days', type: 'number', min: 0, max: 30, step: 1, inputmode: 'numeric',
    value: override.yearly_trial_days ?? '', placeholder: String(defaults.yearly_trial_days),
  });

  const error = h('div', { class: 'form-error', role: 'alert', hidden: true });
  const save = h('button', { class: 'btn btn-primary', type: 'submit' }, 'Save changes');
  const reset = h('button', { class: 'btn btn-ghost', type: 'button' }, 'Reset to server defaults');

  const submit = async (payload) => {
    error.hidden = true;
    save.disabled = true;
    save.classList.add('is-busy');
    try {
      await api('/admin/settings/stripe', { method: 'PUT', body: payload });
      toast('Stripe settings saved. New checkouts use them now.');
      ctx.rerender();
    } catch (err) {
      error.textContent = err.message;
      error.hidden = false;
      save.disabled = false;
      save.classList.remove('is-busy');
    }
  };

  const form = h('form', { class: 'stack', novalidate: true },
    pricesError ? callout('warning', 'Couldn’t load your prices from Stripe, so paste the price IDs instead. ', pricesError.message) : null,
    !stripe.status.secret_key_set ? callout('warning', 'Stripe isn’t connected (no secret key on the server), so new prices can’t be checked or saved yet.') : null,
    h('div', { class: 'grid grid-2' }, monthly.el, yearly.el),
    h('div', { class: 'field' },
      h('label', { for: 'trial-days' }, 'Free trial on the yearly plan (days)'),
      trial,
      h('p', { class: 'field-help' }, `First-time subscribers only. 0 turns the trial off. Leave empty for the server default (${defaults.yearly_trial_days} days).`)),
    callout('neutral', h('ul', { class: 'bullets' },
      h('li', null, 'New web checkouts use the new prices right away. Existing subscribers keep the price they signed up with. To move them, change their subscription in the Stripe dashboard.'),
      h('li', null, 'App Store and Google Play prices and trials are set in App Store Connect and the Google Play Console, not here.'),
      h('li', null, 'The prices shown on the website are written in ', mono('website/src/components/Pricing.tsx'), '. Update them there too.'))),
    error,
    h('div', { class: 'form-actions' },
      h('p', { class: 'muted small' }, stripe.updated_at
        ? `Last changed ${fmtDateTime(stripe.updated_at)}${stripe.updated_by ? ` by ${stripe.updated_by}` : ''}.`
        : 'Never changed here: using the server defaults.'),
      h('div', { class: 'btn-row' }, reset, save)));

  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const raw = trial.value.trim();
    let days = null;
    if (raw !== '') {
      days = Number(raw);
      if (!Number.isInteger(days) || days < 0 || days > 30) {
        error.textContent = 'The free trial must be a whole number of days from 0 to 30.';
        error.hidden = false;
        return;
      }
    }
    const pm = monthly.value();
    const py = yearly.value();
    if (pm === null || py === null) {
      error.textContent = 'Paste the Stripe price ID (it starts with price_), or pick a price from the list.';
      error.hidden = false;
      return;
    }
    submit({ price_monthly: pm, price_yearly: py, yearly_trial_days: days });
  });
  reset.addEventListener('click', async () => {
    const ok = await confirmDialog({
      title: 'Reset to the server defaults?',
      body: h('p', null, 'Web checkout goes back to the prices in ', mono('.env.production'), ' and a ',
        String(defaults.yearly_trial_days), '-day yearly trial.'),
      confirmLabel: 'Reset',
    });
    if (ok) submit({ price_monthly: '', price_yearly: '', yearly_trial_days: null });
  });

  const inUse = details([
    ['Monthly', effective.price_monthly ? mono(effective.price_monthly) : h('span', { class: 'muted' }, 'None, so monthly checkout is off')],
    ['Yearly', effective.price_yearly ? mono(effective.price_yearly) : h('span', { class: 'muted' }, 'None, so yearly checkout is off')],
    ['Yearly free trial', effective.yearly_trial_days ? `${effective.yearly_trial_days} days` : 'Off'],
  ]);

  return card('Prices and free trial', h('div', { class: 'stack' },
    h('div', null, h('h3', { class: 'subhead' }, 'In use now'), inUse),
    h('hr', { class: 'divider' }),
    form),
  { subtitle: 'What web checkout charges. Changes are checked with Stripe before they’re saved.' });
}

// ----- Read-only server settings -----

function adminsCard(admins) {
  return card('Admin access', h('div', { class: 'stack-sm' },
    admins.length
      ? h('ul', { class: 'plain-list' }, admins.map((e) => h('li', null, mono(e))))
      : h('p', { class: 'muted' }, 'No admins configured.'),
    h('p', { class: 'muted small' }, 'To add or remove an admin, edit ', mono('ADMIN_EMAILS'),
      ' (comma-separated) in ', mono('.env.production'), ' and restart the API. Each admin signs in with their own Lively account.')));
}

function moderationCard(m) {
  return card('Moderation', h('div', { class: 'stack-sm' },
    details([
      ['Report e-mails', m.email_set ? badge('On', 'good') : badge('Off: MODERATION_EMAIL is empty', 'warning')],
      ['Auto-hide', m.autohide_threshold > 0
        ? `After ${m.autohide_threshold} reports from different people`
        : 'Off'],
    ]),
    h('p', { class: 'muted small' }, 'Set with ', mono('MODERATION_EMAIL'), ' and ', mono('MODERATION_AUTOHIDE_THRESHOLD'), ' in ', mono('.env.production'), '.')));
}
