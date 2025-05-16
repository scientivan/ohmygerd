# OhMyGERD

## 📋Overview

OhMyGERD is a gamified mobile app designed to support young individuals—especially busy college students—in managing Gastroesophageal Reflux Disease (GERD). This condition is often triggered by irregular eating patterns, skipped meals, and certain foods or drinks. OhMyGERD helps users build healthy habits by providing smart reminders, easy tracking of food and drink intake, and AI-powered tools to avoid triggers. Through personalized features and a fun, interactive experience, OhMyGERD empowers users to stay consistent, reduce symptoms, and take control of their lifestyle—without feeling overwhelmed by medical jargon or boring routines.

## 🚀 Main Features

- 🔔 **Smart Reminder & Connection** — Sends timely reminders for meals while enabling support from loved ones.
- 🍽️ **Food & Drink Agenda** — Helps users log meals and drinks to avoid GERD triggers.
- 🤖 **Gerdian (v1.0)** — A friendly chatbot that offers real-time support, education, tips, and calming techniques during GERD episodes.
- 📅 **Streak & Activity Record Calendar** — Tracks habits, symptom patterns, and progress to encourage consistency and lifestyle improvements.
- 🧠 **AI-powered Food Check & Recommendation** — Scans and evaluates food items, providing tailored GERD-friendly suggestions based on user data.

## 🛠️ Tech Stack

- Framework: Flutter 3.29.3 with Dart Programming Language 3.7.2
- Authentication: Firebase Authentication
- Backend: Node.js & Firebase Function
- Database: Firebase Firestore
- Storage: Google Drive
- AI Integration: Gemini 2.0 Flash
- Camera Integration: image-picker from Flutter
- Mailing: Google Mail & Google Contacts
- API Request: http package from Flutter
- Nearby Restaurant: Google Places API & Geolocator package from Flutter

## 🚀Getting Started

### Prerequisites

- Install [Flutter](https://flutter.dev/)
- Install [Node.js](https://nodejs.org/)
- Set up [Firebase Account](https://firebase.google.com/) and create a new project
- Set up [Google Cloud Platform](https://cloud.google.com/) account for API access
- Install [Git](https://git-scm.com/downloads)

### API Keys Setup

Before installation, you'll need to obtain the following API keys:

1. Firebase Project Setup:

   - Create a new Firebase project at Firebase Console
   - Enable Authentication, Firestore, and Storage services
   - Generate a serviceAccountKey.json file from Project Settings > Service Accounts

2. Google API Keys:

   - Create a project in Google Cloud Console
   - Enable Google Drive API, Gmail API, Google Places API, and People API
   - Create OAuth 2.0 credentials for email services
   - Generate API keys for Places API

3. Gemini API Key:
   - Visit Google AI Studio
   - Create an API key for Gemini access

### Installation

1. Clone the repository

```bash
git clone https://github.com/scientivan/ohmygerd.git
cd ohmygerd
```

2. Change directory to backend

```bash
cd be
```

3. Create a `.env` file in the root of the directory

```env
NODE_ENV=development
PORT=3000

NODEMAILER_CLIENT_ID=your_nodemailer_client_id
NODEMAILER_CLIENT_SECRET=your_nodemailer_client_secret
REDIRECT_URI=your_redirect_uri
ACCESS_TOKEN=your_access_token
REFRESH_TOKEN=your_refresh_token
EMAIL_ADMIN=youremail@gmail.com

GEMINI_API_KEY=your_gemini_api_key

GOOGLE_DRIVE_FOLDER_ID=your_google_drive_folder_id
GOOGLE_API_KEY=your_google_api_key

```

4. Create a `serviceAccountKey.json` file in the rood of the directory (format shown below):

```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "your-private-key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nYOUR_PRIVATE_KEY\\n-----END PRIVATE KEY-----\\n",
  "client_email": "firebase-adminsdk-xxx@your-project-id.iam.gserviceaccount.com",
  "client_id": "your-client-id",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxx%40your-project-id.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
```

5. Install backend dependencies

```bash
npm install
npm install nodemon
# or
yarn install
yarn install nodemon
# or
pnpm install
pnpm install nodemon
```

6. Start the development server

```bash
npm start
# or
yarn start
# or
pnpm start
```

7. Change the directory to frontend

```bash
cd ..
cd fe
```

8. Create a `.env` file in the root of the directory

```env
API_URL=your localhost API URL
```

9. Install depedencies

```bash
flutter pub get
```

10. Run the app

```bash
flutter run
```

## Project Structure

```
└── ohmygerd/
    ├── fe/                          # Frontend Flutter application
    │   ├── lib/
    │   │   ├── core/                # Core utilities and constants
    │   │   ├── data/                # Data layer
    │   │   │   ├── models/          # Data models
    │   │   │   └── services/        # API and repository services
    │   │   └── presentation/        # UI layer
    │   │       ├── components/      # Reusable UI components
    │   │       ├── layouts/         # Layout templates
    │   │       ├── pages/           # App screens organized by feature
    │   │       │   ├── auth/        # Authentication screens
    │   │       │   ├── image_process/
    │   │       │   │   ├── by_time/ # Time-based food processing
    │   │       │   │   └── scan_only/ # Food scanning features
    │   │       │   ├── intro/       # Onboarding screens
    │   │       │   ├── main/        # Main app screens
    │   │       │   ├── others/      # Miscellaneous screens
    │   │       │   └── settings/    # User settings
    │   │       ├── providers/       # State management
    │   │       └── routes/          # Navigation routes
    │   ├── .env                     # Environment variables
    │   └── pubspec.yaml             # Flutter dependencies
    └── be/                          # Backend NodeJS application
        ├── config/                  # Server configuration
        ├── controllers/             # API controllers
        ├── functions/               # Firebase Cloud Functions
        │   ├── config/              # Functions configuration
        │   ├── lib/                 # Function libraries
        │   └── utils/               # Function utilities
        ├── routes/                  # API routes
        ├── utils/                   # Utility functions
        ├── app.js                   # Main server file
        ├── .env                     # Environment variables
        └── serviceAccountKey.json   # Firebase service account key
```

## 📱Application Features

### Smart Reminder & Connection

- Sends timely notifications for meals and snack times
- Lets you connect up to 3 family members or friends as support
- Offers flexible scheduling based on your personal preferences

### Food & Drink Agenda

- Tracks your daily meals and water intake
- Detects GERD-triggering ingredients in your meals
- Stores your food history for better tracking and analysis

### Gerdian (v1.0)

- Your personalized chatbot, available 24/7
- Shares helpful tips, facts, and education about GERD and related conditions
- Offers calming suggestions during symptom flare-ups

### Streak & Activity Record Calendar

- Adds a gamified streak system to boost consistency
- Tracks your monthly GERD symptoms using a visual calendar
- Logs daily meal entries with detailed ingredients

### AI-powered Food Check & Recommendation

- Instantly scans and analyzes your food using AI
- Recommends GERD-friendly meals based on selected health conditions
- Suggests nearby restaurants that match your dietary needs

## 👥Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch `(git checkout -b feature/new-feature)`
3. Commit your changes `(git commit -m 'Add a ne feature')`
4. Push to the branch `(git push origin feature/new-feature)`
5. Open a Pull Request

## 📄License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏Acknowledgements

This project is made possible thanks to God’s blessings and guidance throughout the journey.

Big shoutout to our amazing team — the brains and hands behind this app:

- Hustler: Fazmi Rizki Al Ghifari

- Hipster: Edeline Felicia Dharmawan

- Hackers: Dien Muhammad Scientivan Kurniapramono (backend) & Aulia Nur Fajri Tri Anggoro (frontend)

We also want to express our gratitude to Google Developer Groups on Campus (GDGoC) UGM for their support, inspiration, and community that helped us grow technically and creatively.

This project is also made possible thanks to the following tools and technologies:

- [Flutter](https://flutter.dev/) and [Dart](https://dart.dev/) — for building the mobile app.
- [Firebase](https://firebase.google.com/) — for Authentication, Firestore, and Cloud Functions.
- [Node.js](https://nodejs.org/) — for backend logic and API integration.
- [Google Drive API](https://developers.google.com/drive) — for secure file storage.
- [Gemini 2.0 Flash](https://deepmind.google/technologies/gemini/) — for AI-powered food analysis.
- [image_picker](https://pub.dev/packages/image_picker) — for camera and gallery image selection.
- [Google Mail API](https://developers.google.com/gmail/api) & [Google Contacts API](https://developers.google.com/people) — for email features.
- [http](https://pub.dev/packages/http) package — for API communication in Flutter.
- [Google Places API](https://developers.google.com/maps/documentation/places/web-service/overview) & [geolocator](https://pub.dev/packages/geolocator) — for nearby restaurant features.

Special thanks to the open-source community for providing these amazing tools 💙

## 🎥 Demo

[Watch the demo here](https://youtu.be/vTXtbkCVKP0)

## 📞 Contact

For questions or support, please reach out via:

- Email: dienmsk030406@gmail.com or ancungaulia@gmail.com
