# Trainee AI

Trainee AI is a Flutter interview preparation app that helps users practice mock interviews with AI-generated questions and AI-powered feedback.

## Features

- Firebase email/password authentication
- Interview practice across multiple categories
- Dynamic question generation using Groq (Llama 3.1)
- Voice answer capture using speech-to-text
- AI answer analysis with per-question breakdown:
  - Confidence
  - Clarity
  - Relevance
  - Fluency
- Interview history and score tracking
- User profile management and dark mode toggle

## Tech Stack

- Flutter + Dart
- Firebase:
  - Firebase Authentication
  - Cloud Firestore
- Provider (state management)
- Groq API (question generation and answer evaluation)
- speech_to_text + permission_handler

## Project Structure

```text
lib/
	main.dart
	models/
	screens/
	services/
	theme/
	utils/
	widgets/

assets/
	icons/
	illustrations/
	images/
```

## Prerequisites

- Flutter SDK with Dart >= 3.3.0 and < 4.0.0
- A Firebase project
- A Groq API key
- (Optional) Firebase CLI for deploying Firestore rules and indexes

## Environment Setup

Create a `.env` file in the project root with the following values:

```env
GROQ_API_KEY=your_groq_api_key

FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_APP_ID=your_firebase_app_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_storage_bucket
```

Notes:

- `.env` is already included in `.gitignore`.
- Firebase is initialized from `.env` in `lib/main.dart`.

## Firebase Setup

1. Create a Firebase project.
2. Enable Authentication with Email/Password sign-in.
3. Create a Cloud Firestore database.
4. Apply Firestore rules and indexes from this repo:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

## Run Locally

```bash
flutter pub get
flutter run
```

## Quality Checks

```bash
flutter analyze
flutter test
```

## Firestore Collections Used

- `users/{uid}`
- `users/{uid}/interviews/{interviewId}`
- `users/{uid}/stats/summary`
- `interview_categories/{categoryId}`
- `interview_categories/{categoryId}/generated_questions/{docId}`
- `quotes/{quoteId}`

## Platform Notes

- Android microphone permission is configured in Android manifest.
- iOS microphone usage description exists in `ios/Runner/Info.plist`.
- The app requires internet connectivity for Firebase and Groq API calls.

## Troubleshooting

- Firebase initialization fails at startup:
  - Confirm all Firebase values in `.env` are correct.
  - Ensure the selected Firebase project matches your app config.
- Groq request fails (401/403/429):
  - Verify `GROQ_API_KEY`.
  - Check Groq usage limits or billing status.
- Firestore permission errors:
  - Deploy `firestore.rules`.
  - Make sure the user is authenticated where required.

## License

This project is currently unlicensed. Add a `LICENSE` file before open-source distribution.
