const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');

const port = 18743;
const base = `http://127.0.0.1:${port}/api/`;
let server;
let customerToken;
let managerToken;

async function request(path, { method = 'GET', body, token } = {}) {
  const response = await fetch(base + path, {
    method,
    headers: {
      ...(body ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const data = response.status === 204 ? null : await response.json();
  return { status: response.status, data };
}

before(async () => {
  server = spawn(process.execPath, ['mock-server.js', '--port', String(port)], {
    cwd: process.cwd(), stdio: 'ignore',
  });
  for (let i = 0; i < 50; i++) {
    try {
      const health = await request('__health');
      if (health.status === 200) break;
    } catch (_) { await new Promise(resolve => setTimeout(resolve, 100)); }
  }
  const customer = await request('auth/login', { method: 'POST', body: { username: 'customer', password: 'customer123' } });
  const manager = await request('auth/login', { method: 'POST', body: { username: 'manager', password: 'manager123' } });
  assert.equal(customer.status, 200);
  assert.equal(manager.status, 200);
  customerToken = customer.data.accessToken;
  managerToken = manager.data.accessToken;
});

after(() => { if (server) server.kill(); });

test('health endpoint responds', async () => {
  const result = await request('__health');
  assert.equal(result.status, 200);
  assert.equal(result.data.status, 'ok');
});

test('customer can create simulated order with server-calculated total', async () => {
  const result = await request('orders', { method: 'POST', token: customerToken, body: { items: [{ productId: 1, quantity: 2 }] } });
  assert.equal(result.status, 201);
  assert.equal(result.data.simulated, true);
  assert.equal(result.data.total, 85.8);
  assert.equal(result.data.items[0].unitPrice, 42.9);
});

test('customer cannot see another customer order and staff can see it', async () => {
  const own = await request('orders', { token: customerToken });
  assert.equal(own.status, 200);
  assert.equal(own.data.items.length, 1);
  const staff = await request('orders', { token: managerToken });
  assert.equal(staff.status, 200);
  assert.equal(staff.data.items.length, 1);
});

test('empty order returns field validation error', async () => {
  const result = await request('orders', { method: 'POST', token: customerToken, body: { items: [] } });
  assert.equal(result.status, 422);
  assert.ok(result.data.errors.items);
});

test('staff can update order status and customer cannot', async () => {
  const forbidden = await request('orders/1', { method: 'PATCH', token: customerToken, body: { status: 'processing' } });
  assert.equal(forbidden.status, 403);
  const updated = await request('orders/1', { method: 'PATCH', token: managerToken, body: { status: 'processing' } });
  assert.equal(updated.status, 200);
  assert.equal(updated.data.status, 'processing');
});

test('invalid status returns 422', async () => {
  const result = await request('orders/1', { method: 'PATCH', token: managerToken, body: { status: 'teleport' } });
  assert.equal(result.status, 422);
});
