# Firebase / Cloud Firestore setup

Campus Supply is prepared for Firebase Authentication + Cloud Firestore.

## 1. Install Firebase CLI

On Windows PowerShell:

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

## 2. Connect this Flutter project

From the repository root:

```powershell
flutterfire configure
```

Select your Firebase project and enable:
- Android
- Web
- iOS (if you plan to ship iOS)

This generates `lib/firebase_options.dart`.

## 3. Initialize Firebase in Flutter

After `flutterfire configure`, update `lib/main.dart`:

```dart
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CampusSupplyApp());
}
```

Keep the existing non-web database seeding logic only if you still need the local SQLite fallback. Once Firestore is fully migrated, the SQLite seed can be removed.

## 4. Enable Cloud Firestore

In Firebase Console:
- Build → Firestore Database
- Create database
- Use production/locked mode
- Choose the region closest to your users

Deploy the repository rules with:

```powershell
firebase deploy --only firestore:rules
```

## 5. Recommended Firestore structure

```
users/{uid}
products/{productId}
categories/{categoryId}
bundles/{bundleId}
wishlists/{uid_productId}
carts/{uid_productId}
orders/{orderId}
reviews/{reviewId}
```

The Flutter service is in:

`lib/database/firestore_database.dart`

It already provides:
- user profiles
- product streaming
- product create/update
- wishlist
- cart
- orders
- reviews

## Important

Do not store passwords in Firestore. Firebase Authentication should handle passwords; Firestore should store the user's profile, role and application data.

Do not commit Firebase service-account private keys. The generated `firebase_options.dart` contains client configuration, not a server private key.
