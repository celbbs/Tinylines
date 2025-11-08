TinyLines: Daily Journaling App
TinyLines is a minimalist journaling app designed to help users build consistent journaling habits.
It features a smooth user interface built with Flutter and integrates with Firebase for user
authentication and cloud storage.
## Features
- User Authentication: Firebase Authentication for secure user sign-up, sign-in, and sign-out.
- Journal Entry Management: Create, view, and save journal entries. Entries are securely stored in
Firebase Firestore.
- Offline Access: Journal entries are saved locally for offline access, with Firestore sync when online.
- Responsive UI: The app is responsive and works across multiple platforms (Web, Android, iOS).
## Getting Started
### Prerequisites
Before you can run the app locally, make sure you have the following installed:
- Flutter: Flutter Installation Guide
- Firebase Project: Set up Firebase for your project (check the Firebase setup guide below).
### Set Up Firebase
1. Go to the Firebase Console.
2. Create a new Firebase project and add Firebase Authentication and Firestore.
3. For the Flutter web app, follow the instructions in the Firebase documentation to configure the
web SDK.
4. Obtain your Firebase config (API keys, project ID, etc.) and integrate them into your project using
the generated firebase_options.dart file.
### Firebase Authentication Integration
- Firebase Authentication is used for sign-up, sign-in, and sign-out. Users' credentials are securely
stored in Firebase and linked to their journal entries.
- Firebase Authentication supports email/password sign-in.
## Running the App
### 1. Clone the Repository
Clone the repository to your local machine:
 git clone https://github.com/celbbs/Tinylines.git
 cd Tinylines
### 2. Install Dependencies
Install the required dependencies using Flutter:
 flutter pub get
### 3. Set Up Firebase
Follow these steps to set up Firebase for your app:
1. Set up your Firebase project using the Firebase Console.
2. Download the google-services.json (for Android) or GoogleService-Info.plist (for iOS).
3. Add Firebase SDK initialization code to your main.dart file (Firebase setup will be in the generated
firebase_options.dart file).
4. Ensure your Firestore rules are set to allow read and write permissions for authenticated users.
### 4. Run the App on Web, Android, or iOS
- To run on the web:
 flutter run -d chrome
- To run on Android:
 flutter run -d android
- To run on iOS:
 flutter run -d ios
## How Flutter Frontend, Firebase Backend, and Authentication Layers Connect
### 1. Frontend (Flutter)
The Flutter frontend is responsible for the app's user interface. Key components include:
- AuthScreen: Allows users to sign in or register using Firebase Authentication. The firebase_auth
package is used to interact with Firebase for user sign-up, sign-in, and sign-out.
- HomeScreen: Displays a calendar of journal entries and allows users to navigate to the Journal
Entry Page for creating or editing entries.
- JournalEntryPage: Provides a page for the user to add or view their journal entries. The entry
content is stored locally and synced with Firebase Firestore.
### 2. Backend (Firebase Firestore)
Firebase Firestore is used to store and retrieve journal entries. Each entry is associated with the
user's Firebase ID to ensure entries are unique to the user.
The journal entries are saved as documents in Firestore, containing the content, timestamps, and
image paths (if any). The entries can be accessed and updated based on the authenticated user's
Firebase ID.
### 3. Authentication Layer (Firebase Authentication)
Firebase Authentication is used for managing users. It handles the sign-up and sign-in process with
email/password authentication.
When a user signs in, Firebase assigns them a unique user ID that is used to associate journal
entries with the user.
This authentication flow is handled by the firebase_auth package in the Flutter app.
## Additional Information
### Dependencies
- firebase_core: Core Firebase services for Flutter.
- firebase_auth: Firebase Authentication for handling sign-up, sign-in, and sign-out.
- cloud_firestore: Firebase Firestore for storing and retrieving journal entries.
- provider: State management for handling app-wide states like user authentication.
- flutter_dotenv: For managing environment variables (if needed).
### Future Work
- Image Attachments: Users will be able to add images to their journal entries.
- Search Functionality: Users can search through their journal entries based on keywords or date
ranges.
- Offline Functionality: Improving the offline experience for users when no internet connection is
available