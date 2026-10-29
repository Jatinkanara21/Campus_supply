# Campus Supply — Demo payment fix (branch `fix/demo-payment-firestore`)

## What was wrong
- Pay Now called the `placeOrder` Cloud Function. Your Firebase project is on the free **Spark** plan, so Cloud Functions were never deployed. The call got **HTTP 404**, and the app showed the generic "check your connection" message.
- Since the 11:34 commit, the live app saved orders only in the browser (SharedPreferences). No order in Firestore, no stock change, admin could not see orders.

## What changed (file by file)
| File | Why |
|---|---|
| `lib/database/firestore_database.dart` | `createOrder` now runs ONE Firestore transaction: read products/bundles → check stock → lower stock → save order. The order ID is a per-checkout key, so pressing Pay Now twice or a network retry never makes a second order or deducts stock twice. `updateOrderStatus` (admin) also runs as a transaction: cancelling puts stock back. Added `OrderException` with clear messages (out of stock, price changed, no internet, permission denied…). The real error is printed in the debug console. |
| `lib/screens/demo_payment_screen.dart` | Pay Now calls `createOrder`. Success is shown only after Firestore confirms the order. UPI/card validation and the design are unchanged. Card/UPI values are never saved. |
| `lib/screens/checkout_screen.dart` | Cash on Delivery uses the same transaction (payment status "pending"). |
| `lib/database/local_demo_orders.dart` | Comment only. Kept so old "saved on this device" orders still show in My Orders. New orders are not saved locally. |
| `lib/main.dart` | Optional `USE_FIREBASE_EMULATOR` flag for local testing. It is OFF in normal builds (GitHub Actions), so the live app always uses real Firebase. |
| `firestore.rules` | Secure rules (details below). |
| `firestore-tests/` | Automatic tests for the rules (local emulator only). |
| `functions/index.js` | Fixed the firebase-admin import bug (`firebase-admin/auth`, `firebase-admin/firestore`). This is only for a future upgrade to Blaze. The app does NOT call functions now. |

## What stays local vs Firestore
- **Firestore (the main source of truth):** products and stock, orders, cart, wishlist.
- **SharedPreferences (only on this device):** login flags (`logged_in`, `user_email`, `user_name`) and old demo orders saved before this fix (read only).

## New security rules (in short)
- A customer can create an order only for their own account, with valid fields (status `pending`, demo payment = `success`, COD = `pending`).
- A customer can only **lower** a product's `stock`, never below 0. This is allowed only in the same transaction that creates their new order, and only by the exact amount written in that order. No other product field can change.
- Customers read only their own orders. Only admins can update or delete orders, or edit products.
- Admin = `users/{uid}.role == 'admin'`. The old `admin == true` check was removed because users can edit their own profile, so anyone could have made themselves admin.

## Tests that were run (on our test machine, not on your live project)
- `flutter analyze`: **0 errors**. 143 old infos/warnings were already there before (146 before the change).
- `flutter build web --release --base-href /Campus_supply/`: **success** (Flutter 3.47.8).
- Firestore rules tests in the emulator: **17/17 passed**. They cover: successful order, retry with the same ID (no double deduction), not enough stock, negative stock, another user's order, not signed in, lowering stock without an order, deducting more than ordered, changing price, reading other users' orders, fake order fields, customer editing an order, admin rights, admin cancel and restock, two buyers racing for the last item (only one wins), old faculty-demo orders.
- Real browser test (headless Chromium + the built app + local Firebase emulator), full flow: sign in → bag → checkout → UPI → Pay Now → "Order confirmed". Stock went 5 → 3, the order was saved in Firestore, and the bag was cleared. Second test: ordered 2 notebooks with only 1 in stock → error "A4 Notebook has only 1 in stock…". The Pay button stayed visible, no order was created and stock did not change.

## Steps for Jatin
1. **Code:** push the branch `fix/demo-payment-firestore` to GitHub and merge it into `main`. (Or replace your files with the ones in the zip and commit.)
2. **Rules (important, do this right after step 1):** Firebase console → Firestore Database → **Rules** → paste the new `firestore.rules` → **Publish**. Without the new rules, the stock update is refused (permission denied) and you will see an error, not a fake success.
3. **Check:** GitHub → **Actions** → "Build and Deploy Flutter Web" must be green. Then open the site, place a demo order, and check Firestore → `orders` (a new document) and `products` (stock went down).
4. Run the rules tests yourself (optional): `cd firestore-tests && npm install && npm test` (needs Java).

## Known limits (honest)
- With no server (Spark plan), the order total is calculated by the app from Firestore prices. The rules cannot fully re-check the price. This is fine for a demo payment, but don't rely on it for real money.
- The rules check that every stock change matches an order. They cannot check that every line in an order also had its stock lowered (rules can't loop). The app always does both in one transaction.
- An admin with only `admin: true` and no `role: 'admin'` loses admin rights in the rules. Your live rules already work this way.
