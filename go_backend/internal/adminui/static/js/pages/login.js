// Sign-in: the same accounts as the app. E-mail code by default
// (/auth/otp/request + /auth/login/otp), or password. Accounts created
// with a code have no password; "Set or reset password" sets one with a
// password_reset code (/auth/password/reset) and then signs in with it.
// Only ADMIN_EMAILS accounts get past /admin/me afterwards.

import { h, callout } from '../ui.js';
import { requestCode, loginWithCode, loginWithPassword, resetPassword } from '../api.js';

// Notices that are good news rather than a problem.
const NEUTRAL_NOTICES = ['You’re signed out.', 'A new code is on its way.'];

const MIN_PASSWORD = 8;
const MAX_PASSWORD = 72; // bcrypt's limit, enforced by the API too

export function render(root, { notice, onSignedIn }) {
  let email = '';
  let step = 'email'; // email | code | password | reset-email | reset
  let codeMinutes = 10;
  const sendCode = async (purpose) => {
    const res = await requestCode(email, purpose);
    if (res?.expires_in > 0) codeMinutes = Math.max(1, Math.round(res.expires_in / 60));
  };

  const box = h('div', { class: 'login-card' });
  const page = h('div', { class: 'login' },
    h('div', { class: 'login-brand' }, h('span', { class: 'brand-mark', 'aria-hidden': 'true' }, 'L'), h('span', null, 'Lively ', h('span', { class: 'brand-sub' }, 'Admin'))),
    box);
  root.replaceChildren(page);

  function messageFor(err) {
    switch (err?.code) {
      case 'user_not_found': return 'There’s no account with that e-mail address.';
      case 'invalid_code': return 'That code is wrong or has expired. Check the latest e-mail, or send a new code.';
      case 'invalid_credentials': return 'E-mail or password is incorrect. If you’ve never set a password, use “Set or reset password”.';
      case 'rate_limited': return 'Too many codes were requested for this e-mail. Wait a few minutes and try again.';
      case 'account_locked': return 'Too many failed attempts. Wait a while, or sign in with an e-mail code.';
      case 'rate_limit_exceeded': return 'Too many attempts from this network. Wait a minute and try again.';
      default: return err?.message || 'Sign-in failed.';
    }
  }

  function form(fields, submitLabel, onSubmit, footer) {
    const error = h('div', { class: 'form-error', role: 'alert', hidden: true });
    const submit = h('button', { class: 'btn btn-primary btn-block', type: 'submit' }, submitLabel);
    const f = h('form', { class: 'stack-sm', novalidate: true }, fields, error, submit, footer);
    f.addEventListener('submit', async (e) => {
      e.preventDefault();
      error.hidden = true;
      submit.disabled = true;
      submit.classList.add('is-busy');
      try {
        await onSubmit();
      } catch (err) {
        error.textContent = messageFor(err);
        error.hidden = false;
        submit.disabled = false;
        submit.classList.remove('is-busy');
      }
    });
    return f;
  }

  function link(label, onClick) {
    const a = h('button', { class: 'link-btn', type: 'button' }, label);
    a.addEventListener('click', onClick);
    return a;
  }

  function go(next, keepNotice = false) {
    step = next;
    if (!keepNotice) notice = null;
    draw();
  }

  function emailField(value) {
    return h('input', { class: 'input', id: 'email', type: 'email', autocomplete: 'username', required: true, value, placeholder: 'you@company.com' });
  }

  function codeField() {
    const input = h('input', {
      class: 'input input-code', id: 'code', inputmode: 'numeric', autocomplete: 'one-time-code',
      maxlength: 6, pattern: '[0-9]{6}', required: true, placeholder: '000000',
    });
    input.addEventListener('input', () => { input.value = input.value.replace(/\D/g, '').slice(0, 6); });
    return input;
  }

  function sentText() {
    return h('p', { class: 'muted' }, 'We sent a 6-digit code to ', h('strong', null, email),
      `. It expires in ${codeMinutes} minute${codeMinutes === 1 ? '' : 's'}.`);
  }

  function resendLink(purpose) {
    return link('Send a new code', async () => {
      try {
        await sendCode(purpose);
        notice = 'A new code is on its way.';
      } catch (err) {
        notice = messageFor(err);
      }
      draw();
    });
  }

  function draw() {
    box.replaceChildren();
    if (notice) box.append(callout(NEUTRAL_NOTICES.includes(notice) ? 'neutral' : 'warning', notice));

    if (step === 'email') {
      const input = emailField(email);
      box.append(
        h('h1', null, 'Sign in'),
        h('p', { class: 'muted' }, 'Use your Lively account. We’ll e-mail you a 6-digit code.'),
        form(
          h('div', { class: 'field' }, h('label', { for: 'email' }, 'E-mail'), input),
          'E-mail me a code',
          async () => {
            email = input.value.trim();
            if (!email.includes('@')) throw new Error('Enter a valid e-mail address.');
            await sendCode('login');
            go('code');
          },
          h('p', { class: 'login-alt' }, link('Sign in with a password instead', () => {
            email = input.value.trim();
            go('password');
          }))));
      input.focus();
      return;
    }

    if (step === 'code') {
      const input = codeField();
      box.append(
        h('h1', null, 'Check your e-mail'),
        sentText(),
        form(
          h('div', { class: 'field' }, h('label', { for: 'code' }, 'Code'), input),
          'Sign in',
          async () => {
            if (input.value.length !== 6) throw new Error('Enter the 6-digit code from the e-mail.');
            await loginWithCode(email, input.value);
            await onSignedIn();
          },
          h('p', { class: 'login-alt' },
            resendLink('login'),
            ' · ',
            link('Use a password instead', () => go('password')),
            ' · ',
            link('Use a different e-mail', () => go('email')))));
      input.focus();
      return;
    }

    if (step === 'reset-email') {
      const input = emailField(email);
      box.append(
        h('h1', null, 'Set a password'),
        h('p', { class: 'muted' }, 'Works whether you’ve never had a password or forgot it. We’ll e-mail a 6-digit code to confirm it’s you.'),
        form(
          h('div', { class: 'field' }, h('label', { for: 'email' }, 'E-mail'), input),
          'E-mail me a code',
          async () => {
            email = input.value.trim();
            if (!email.includes('@')) throw new Error('Enter a valid e-mail address.');
            await sendCode('password_reset');
            go('reset');
          },
          h('p', { class: 'login-alt' }, link('Back to sign in', () => go('password')))));
      input.focus();
      return;
    }

    if (step === 'reset') {
      const code = codeField();
      const pw = h('input', { class: 'input', id: 'new-password', type: 'password', autocomplete: 'new-password', required: true, minlength: MIN_PASSWORD, maxlength: MAX_PASSWORD });
      const pw2 = h('input', { class: 'input', id: 'new-password-2', type: 'password', autocomplete: 'new-password', required: true, maxlength: MAX_PASSWORD });
      box.append(
        h('h1', null, 'Set a password'),
        sentText(),
        form(
          [h('div', { class: 'field' }, h('label', { for: 'code' }, 'Code'), code),
            h('div', { class: 'field' }, h('label', { for: 'new-password' }, 'New password'), pw,
              h('p', { class: 'field-help' }, `At least ${MIN_PASSWORD} characters. This also becomes your password in the app.`)),
            h('div', { class: 'field' }, h('label', { for: 'new-password-2' }, 'Repeat the new password'), pw2)],
          'Save password and sign in',
          async () => {
            if (code.value.length !== 6) throw new Error('Enter the 6-digit code from the e-mail.');
            if (pw.value.length < MIN_PASSWORD) throw new Error(`The password needs at least ${MIN_PASSWORD} characters.`);
            if (new TextEncoder().encode(pw.value).length > MAX_PASSWORD) throw new Error('That password is too long.');
            if (pw.value !== pw2.value) throw new Error('The two passwords don’t match.');
            await resetPassword(email, code.value, pw.value);
            await loginWithPassword(email, pw.value);
            await onSignedIn();
          },
          h('p', { class: 'login-alt' },
            resendLink('password_reset'),
            ' · ',
            link('Back to sign in', () => go('password')))));
      code.focus();
      return;
    }

    // password
    const emailInput = emailField(email);
    const pw = h('input', { class: 'input', id: 'password', type: 'password', autocomplete: 'current-password', required: true, maxlength: MAX_PASSWORD });
    box.append(
      h('h1', null, 'Sign in'),
      form(
        [h('div', { class: 'field' }, h('label', { for: 'email' }, 'E-mail'), emailInput),
          h('div', { class: 'field' }, h('label', { for: 'password' }, 'Password'), pw)],
        'Sign in',
        async () => {
          email = emailInput.value.trim();
          if (!email.includes('@') || !pw.value) throw new Error('Enter your e-mail and password.');
          await loginWithPassword(email, pw.value);
          await onSignedIn();
        },
        h('p', { class: 'login-alt' },
          link('Set or reset password', () => {
            email = emailInput.value.trim();
            go('reset-email');
          }),
          ' · ',
          link('E-mail me a code instead', () => {
            email = emailInput.value.trim();
            go('email');
          }))));
    (email ? pw : emailInput).focus();
  }

  draw();
}
