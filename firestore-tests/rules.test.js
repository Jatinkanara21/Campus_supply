// Security-rules tests for orders + stock. Runs ONLY against the local emulator.
// cd firestore-tests && npm install && npm test

const fs = require('fs');
const assert = require('assert');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, runTransaction, serverTimestamp, collection, query, where, getDocs, writeBatch, increment } = require('firebase/firestore');

let env;
const PROJECT = 'demo-campus-supply';
const results = [];

function orderData(uid, key, deductions, extra = {}) {
  return {
    orderKey: key, userId: uid,
    items: [{ itemType: 'product', productId: 'pen', name: 'Pen', price: 10, imageUrl: '', quantity: deductions.pen || 1 }],
    total: 10 * (deductions.pen || 1), status: 'pending',
    paymentMethod: 'demo_upi', paymentMode: 'demo', paymentStatus: 'success',
    demoTransactionId: 'DEMO-TXN-' + key.slice(0, 12).toUpperCase(),
    customerName: 'Test Student', customerPhone: '9999999999', customerEmail: 'a@test.dev',
    deliveryAddress: 'Hostel A', deliveryCity: 'Vadodara', deliveryPinCode: '390001',
    stockDeducted: true, stockRestocked: false, stockDeductions: deductions,
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...extra,
  };
}

// Same logic as FirestoreDatabase.createOrder in the Flutter app.
async function placeOrder(db, uid, key, qtyByProduct) {
  return runTransaction(db, async (t) => {
    const orderRef = doc(db, 'orders', key);
    const existing = await t.get(orderRef);
    if (existing.exists()) return { orderId: key, alreadyExisted: true };
    const next = {};
    for (const [pid, qty] of Object.entries(qtyByProduct)) {
      const snap = await t.get(doc(db, 'products', pid));
      if (!snap.exists()) throw new Error('missing product');
      const stock = Math.max(0, Math.floor(Number(snap.data().stock) || 0));
      if (stock < qty) { const e = new Error(`${snap.data().name} has only ${stock} in stock`); e.code = 'out-of-stock'; throw e; }
      next[pid] = stock - qty;
    }
    for (const [pid, remaining] of Object.entries(next)) {
      t.update(doc(db, 'products', pid), { stock: remaining, lastOrderId: key, updatedAt: serverTimestamp() });
    }
    t.set(orderRef, orderData(uid, key, qtyByProduct));
    return { orderId: key, alreadyExisted: false };
  });
}

async function stockOf(pid) {
  let v;
  await env.withSecurityRulesDisabled(async (ctx) => { v = (await getDoc(doc(ctx.firestore(), 'products', pid))).data().stock; });
  return v;
}
async function orderExists(id) {
  let v;
  await env.withSecurityRulesDisabled(async (ctx) => { v = (await getDoc(doc(ctx.firestore(), 'orders', id))).exists(); });
  return v;
}

async function run(name, fn) {
  try { await fn(); results.push(['PASS', name]); console.log('PASS', name); }
  catch (e) { results.push(['FAIL', name, String(e && e.message || e)]); console.log('FAIL', name, e && e.message); }
}

(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: { rules: fs.readFileSync(require('path').join(__dirname, '..', 'firestore.rules'), 'utf8') }, // host/port come from FIRESTORE_EMULATOR_HOST (set by emulators:exec)
  });
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'products', 'pen'), { name: 'Pen', price: 10, stock: 5, imageUrl: '' });
    await setDoc(doc(db, 'products', 'book'), { name: 'Notebook', price: 50, stock: 2, imageUrl: '' });
    await setDoc(doc(db, 'users', 'admin1'), { role: 'admin', name: 'Admin' });
    await setDoc(doc(db, 'users', 'alice'), { role: 'user', name: 'Alice' });
    await setDoc(doc(db, 'users', 'mallory'), { role: 'user', admin: true, name: 'Mallory' });
  });
  const alice = env.authenticatedContext('alice').firestore();
  const bob = env.authenticatedContext('bob').firestore();
  const anon = env.unauthenticatedContext().firestore();
  const admin = env.authenticatedContext('admin1').firestore();
  const mallory = env.authenticatedContext('mallory').firestore();

  await run('1 success: signed-in user places order, stock 5 -> 3, order saved', async () => {
    const r = await assertSucceeds(placeOrder(alice, 'alice', 'orderA1', { pen: 2 }));
    assert.equal(r.alreadyExisted, false);
    assert.equal(await stockOf('pen'), 3);
    assert.equal(await orderExists('orderA1'), true);
  });

  await run('2 retry with same order id does not double-deduct (returns existing order)', async () => {
    const r = await assertSucceeds(placeOrder(alice, 'alice', 'orderA1', { pen: 2 }));
    assert.equal(r.alreadyExisted, true);
    assert.equal(await stockOf('pen'), 3);
  });

  await run('3 insufficient stock rejected (book stock 2, asks 3), nothing written', async () => {
    let err;
    try { await placeOrder(alice, 'alice', 'orderA2', { book: 3 }); } catch (e) { err = e; }
    assert.ok(err && err.code === 'out-of-stock', 'expected out-of-stock, got ' + (err && err.message));
    assert.equal(await stockOf('book'), 2);
    assert.equal(await orderExists('orderA2'), false);
  });

  await run('4 negative stock blocked by rules (stock 2 -> -1 with matching order)', async () => {
    const b = writeBatch(alice);
    b.update(doc(alice, 'products', 'book'), { stock: -1, lastOrderId: 'orderNeg', updatedAt: serverTimestamp() });
    b.set(doc(alice, 'orders', 'orderNeg'), orderData('alice', 'orderNeg', { book: 3 }));
    await assertFails(b.commit());
    assert.equal(await stockOf('book'), 2);
  });

  await run('5 order for ANOTHER user blocked (alice writes userId bob)', async () => {
    await assertFails(placeOrder(alice, 'bob', 'orderX1', { pen: 1 }));
    assert.equal(await stockOf('pen'), 3);
  });

  await run('6 unauthenticated user blocked (order + stock)', async () => {
    await assertFails(placeOrder(anon, 'nobody', 'orderU1', { pen: 1 }));
    await assertFails(updateDoc(doc(anon, 'products', 'pen'), { stock: 2, updatedAt: serverTimestamp() }));
    await assertFails(getDoc(doc(anon, 'orders', 'orderA1')));
    assert.equal(await stockOf('pen'), 3);
  });

  await run('7 stock decrement WITHOUT creating an order is blocked', async () => {
    await assertFails(updateDoc(doc(alice, 'products', 'pen'), { stock: 2, lastOrderId: 'ghost', updatedAt: serverTimestamp() }));
  });

  await run('8 deducting more than the order says is blocked (order says 1, stock -3)', async () => {
    const b = writeBatch(alice);
    b.update(doc(alice, 'products', 'pen'), { stock: 0, lastOrderId: 'orderMis', updatedAt: serverTimestamp() });
    b.set(doc(alice, 'orders', 'orderMis'), orderData('alice', 'orderMis', { pen: 1 }));
    await assertFails(b.commit());
    assert.equal(await stockOf('pen'), 3);
  });

  await run('9 customer cannot increase stock or change price/name', async () => {
    await assertFails(updateDoc(doc(alice, 'products', 'pen'), { stock: 100, updatedAt: serverTimestamp() }));
    const b = writeBatch(alice);
    b.update(doc(alice, 'products', 'pen'), { stock: 2, price: 1, lastOrderId: 'orderP', updatedAt: serverTimestamp() });
    b.set(doc(alice, 'orders', 'orderP'), orderData('alice', 'orderP', { pen: 1 }));
    await assertFails(b.commit());
  });

  await run('10 re-using an EXISTING order id to deduct again is blocked', async () => {
    // Bob tries to piggy-back stock writes on alice's existing order id.
    await assertFails(updateDoc(doc(alice, 'products', 'pen'), { stock: 1, lastOrderId: 'orderA1', updatedAt: serverTimestamp() }));
  });

  await run('11 users read only their own orders (bob cannot read alice order; alice can; list query works)', async () => {
    await assertFails(getDoc(doc(bob, 'orders', 'orderA1')));
    await assertSucceeds(getDoc(doc(alice, 'orders', 'orderA1')));
    const qs = await assertSucceeds(getDocs(query(collection(alice, 'orders'), where('userId', '==', 'alice'))));
    assert.ok(qs.size >= 1);
    await assertFails(getDocs(collection(bob, 'orders')));
  });

  await run('12 order with bad fields rejected (status delivered / paymentStatus faked on COD / extra field)', async () => {
    await assertFails(setDoc(doc(alice, 'orders', 'bad1'), orderData('alice', 'bad1', { pen: 1 }, { status: 'delivered' })));
    await assertFails(setDoc(doc(alice, 'orders', 'bad2'), orderData('alice', 'bad2', { pen: 1 }, { paymentMethod: 'cash_on_delivery', paymentMode: 'cod', paymentStatus: 'success' })));
    await assertFails(setDoc(doc(alice, 'orders', 'bad3'), orderData('alice', 'bad3', { pen: 1 }, { isAdminApproved: true })));
    await assertFails(setDoc(doc(alice, 'orders', 'bad4'), orderData('alice', 'bad4', { pen: 1 }, { orderKey: 'different' })));
  });

  await run('13 customer cannot update or delete an order (only admin)', async () => {
    await assertFails(updateDoc(doc(alice, 'orders', 'orderA1'), { status: 'delivered' }));
    await assertSucceeds(updateDoc(doc(admin, 'orders', 'orderA1'), { status: 'confirmed', updatedAt: serverTimestamp() }));
  });

  await run('14 admin (role=admin) can still edit products; self-set admin:true is NOT admin', async () => {
    await assertSucceeds(updateDoc(doc(admin, 'products', 'pen'), { price: 12, stock: 10 }));
    await assertFails(updateDoc(doc(mallory, 'products', 'pen'), { price: 1 }));
    await env.withSecurityRulesDisabled(async (ctx) => updateDoc(doc(ctx.firestore(), 'products', 'pen'), { price: 10, stock: 3 }));
  });

  await run('15 admin cancel restock transaction (client updateOrderStatus) allowed for admin, blocked for customer', async () => {
    const restock = (db) => runTransaction(db, async (t) => {
      const o = await t.get(doc(db, 'orders', 'orderA1'));
      const p = await t.get(doc(db, 'products', 'pen'));
      t.update(doc(db, 'products', 'pen'), { stock: p.data().stock + 2, updatedAt: serverTimestamp() });
      t.update(doc(db, 'orders', 'orderA1'), { status: 'cancelled', stockRestocked: true, updatedAt: serverTimestamp() });
    });
    await assertFails(restock(alice));
    await assertSucceeds(restock(admin));
    assert.equal(await stockOf('pen'), 5);
  });

  await run('16 two competing orders for the last items: only one succeeds, stock never negative', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => updateDoc(doc(ctx.firestore(), 'products', 'book'), { stock: 1 }));
    const outcomes = await Promise.allSettled([
      placeOrder(alice, 'alice', 'raceA', { book: 1 }),
      placeOrder(bob, 'bob', 'raceB', { book: 1 }),
    ]);
    const ok = outcomes.filter((o) => o.status === 'fulfilled').length;
    assert.equal(ok, 1, 'expected exactly one success, got ' + ok + ' ' + JSON.stringify(outcomes.map(o=>o.status + ':' + (o.reason && o.reason.message))));
    assert.equal(await stockOf('book'), 0);
  });

  await run('17 faculty-demo seed order rule still works', async () => {
    await assertSucceeds(setDoc(doc(alice, 'orders', 'seed1'), { userId: 'alice', isDemo: true, demoBatch: 'faculty_demo_v1', total: 0 }));
  });

  await env.cleanup();
    const failed = results.filter(r => r[0] !== 'PASS').length;
  console.log(`\n${results.length - failed}/${results.length} passed`);
  process.exit(failed ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(2); });
