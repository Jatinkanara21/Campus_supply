# Campus Supply

**Campus Supply** is a Flutter-based student supply platform designed to help university students discover and manage stationery, art, design, and other academic supplies in one place.

> Built as an independent developer project by Jatinkanara21.

## Why Campus Supply?

University students often need different supplies for classes, assignments, projects, and creative work. Campus Supply aims to make that discovery experience simpler through a focused, student-friendly interface.

## Current Technology

- **Flutter / Dart** — cross-platform application
- **Firebase Core** — Firebase initialization
- **Firebase Authentication** — user authentication
- **Cloud Firestore** — application data
- **Firebase Storage** — image/file storage
- **Google Fonts** — typography
- **Image Picker** — image selection
- **HTTP** — network requests
- **Flutter SVG** — SVG asset support

## Current Project Structure

```text
lib/
├── database/
├── screens/
├── services/
├── theme/
├── widgets/
├── firebase_options.dart
└── main.dart

assets/
├── image/
└── images/
```

## AI Roadmap

A planned AI layer will use an LLM to make Campus Supply more useful for students. Potential capabilities include:

- Natural-language product discovery
- Personalized academic-supply recommendations
- Help finding supplies for assignments or projects
- Conversational product/category assistance
- Summarizing product information
- Student-friendly explanations and guidance

**Important:** AI integration is a planned development direction unless explicitly implemented in the current release.

## Development Status

Campus Supply is an actively developed independent project. The repository and web deployment are being improved iteratively, including Firebase integration, image handling, UI, and web deployment.

## Links

- **GitHub:** https://github.com/Jatinkanara21/Campus_supply
- **Web demo:** https://campus-supply.vercel.app

## Running Locally

Make sure Flutter is installed, then:

```bash
flutter pub get
flutter run
```

For a production web build:

```bash
flutter build web --release
```

## Firebase

The project uses FlutterFire configuration for Firebase services. Do not commit private service-account credentials, API secrets, or other sensitive credentials to the repository.

## Future Direction

The long-term goal is to develop Campus Supply into a practical student-focused platform with reliable data, useful discovery tools, responsible AI assistance, and a polished cross-platform experience.

## License

This repository currently does not declare an open-source license. All rights remain with the repository owner unless a license is added.
