// API client for the admin panel. Same origin as the API, so no CORS.
//
// The session (short-lived access token + refresh token) is kept in
// sessionStorage: it survives a reload but ends when the tab closes, and
// is never sent anywhere except this API's Authorization header.

const BASE = '/api/v1';
const SESSION_KEY = 'lively-admin-session';

export class ApiError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

let session = readSession();
let onUnauthorized = null;
let refreshing = null;

function readSession() {
  try {
    const raw = sessionStorage.getItem(SESSION_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

function writeSession(next) {
  session = next;
  try {
    if (next) sessionStorage.setItem(SESSION_KEY, JSON.stringify(next));
    else sessionStorage.removeItem(SESSION_KEY);
  } catch {
    // Storage blocked (private mode): the session lives in memory only.
  }
}

export const getSession = () => session;
export const clearSession = () => writeSession(null);

/** Called when the session can't be refreshed (expired / revoked / banned). */
export function setUnauthorizedHandler(fn) {
  onUnauthorized = fn;
}

async function parse(res) {
  if (res.status === 204) return null;
  try {
    return await res.json();
  } catch {
    return null;
  }
}

function toError(res, body) {
  const code = body?.error?.code || `http_${res.status}`;
  const message = body?.error?.message || `Request failed (${res.status})`;
  return new ApiError(res.status, code, message);
}

async function send(url, init) {
  try {
    return await fetch(url, { cache: 'no-store', credentials: 'omit', ...init });
  } catch {
    throw new ApiError(0, 'network', 'Can’t reach the server. Check your connection and try again.');
  }
}

// ----- Public auth endpoints (sign-in) -----

async function authCall(path, body) {
  const res = await send(BASE + path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify(body),
  });
  const data = await parse(res);
  if (!res.ok) throw toError(res, data);
  return data;
}

/** purpose: login | password_reset */
export async function requestCode(email, purpose) {
  return authCall('/auth/otp/request', { email, purpose });
}

/** Sets a new password with a password_reset code (also works for accounts that never had one). */
export async function resetPassword(email, code, newPassword) {
  return authCall('/auth/password/reset', { email, code, new_password: newPassword });
}

function startSession(data, email) {
  const tokens = data?.data?.tokens;
  if (!tokens?.access_token) throw new ApiError(500, 'bad_response', 'Unexpected sign-in response.');
  writeSession({ access: tokens.access_token, refresh: tokens.refresh_token, email });
}

export async function loginWithCode(email, code) {
  startSession(await authCall('/auth/login/otp', { email, code }), email);
}

export async function loginWithPassword(email, password) {
  startSession(await authCall('/auth/login', { email, password }), email);
}

export async function logout() {
  const refresh = session?.refresh;
  writeSession(null);
  if (!refresh) return;
  try {
    await authCall('/auth/logout', { refresh_token: refresh });
  } catch {
    // Best effort: the local session is gone either way.
  }
}

async function refreshSession() {
  if (!session?.refresh) return false;
  if (!refreshing) {
    refreshing = (async () => {
      try {
        const data = await authCall('/auth/refresh', { refresh_token: session.refresh });
        const t = data?.data?.tokens;
        if (!t?.access_token) return false;
        writeSession({ ...session, access: t.access_token, refresh: t.refresh_token });
        return true;
      } catch {
        return false;
      } finally {
        refreshing = null;
      }
    })();
  }
  return refreshing;
}

// ----- Authenticated calls -----

/**
 * api('/admin/users', {query: {q: 'x'}}) → parsed JSON.
 * Refreshes the access token once on a 401 and retries.
 */
export async function api(path, { method = 'GET', body, query } = {}) {
  let url = BASE + path;
  if (query) {
    const qs = new URLSearchParams();
    for (const [k, v] of Object.entries(query)) {
      if (v !== undefined && v !== null && v !== '') qs.set(k, String(v));
    }
    const str = qs.toString();
    if (str) url += `?${str}`;
  }
  const doFetch = () => {
    const headers = { Accept: 'application/json' };
    if (body !== undefined) headers['Content-Type'] = 'application/json';
    if (session?.access) headers.Authorization = `Bearer ${session.access}`;
    return send(url, { method, headers, body: body !== undefined ? JSON.stringify(body) : undefined });
  };

  let res = await doFetch();
  if (res.status === 401 && (await refreshSession())) res = await doFetch();
  const data = await parse(res);
  if (res.status === 401 || (res.status === 403 && data?.error?.code === 'account_banned')) {
    writeSession(null);
    onUnauthorized?.();
    throw new ApiError(401, 'unauthorized', 'Your session has ended. Please sign in again.');
  }
  if (!res.ok) throw toError(res, data);
  return data;
}
