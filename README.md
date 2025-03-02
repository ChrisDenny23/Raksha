🌍 Disaster Management App

A Flutter-based disaster management application that helps users stay informed about disaster alerts, share emergency locations, and access safety tips in real-time. The app is powered by Firebase for backend services, including authentication, database storage, and notifications.

🚀 Features

🌦 Live Weather Updates – Get real-time weather updates and risk levels.

📍 Location Tracking – View your current location on a map and share it in emergencies.

⚠ Disaster Alerts – Stay updated with disaster-related news and alerts.

🆘 Emergency SOS – Send an SOS message with your location to emergency contacts via WhatsApp.

📞 Emergency Contacts – Add and manage emergency contacts.

📝 Safety Tips & Guidelines – Access essential safety tips, helplines, and do’s & don’ts for disaster preparedness.

🔍 Incident Reporting – Report disaster incidents in your vicinity.

🤝 Volunteering – Connect with volunteer organizations for disaster relief efforts.


🛠 Tech Stack

Flutter – Cross-platform UI framework.

Firebase – Backend services for authentication, database, and notifications.

Firestore Database

Firebase Authentication

Firebase Cloud Messaging (FCM)


Google Maps API – Location services and mapping.


📷 Screenshots

🏗 Installation & Setup

1. Clone the repository

git clone https://github.com/ChrisDenny23/Raksha.git
cd Raksha


2. Install dependencies

flutter pub get


3. Setup Firebase

Create a Firebase project at Firebase Console

Enable Firestore, Authentication, and Cloud Messaging.

Download the google-services.json (for Android) and GoogleService-Info.plist (for iOS) and place them in the android/app and ios/Runner directories respectively.



4. Run the app

flutter run



🔥 Firebase Configuration

Make sure you have the following Firebase services enabled:

Authentication (Google Sign-In, Email/Password)

Firestore Database (For storing user data, emergency contacts, and disaster reports)

Cloud Messaging (FCM) (For push notifications and alerts)


🎨 UI Design

The UI follows a dark-themed, modern, and minimalistic design for better visibility during emergencies.

🤝 Contributing

Want to contribute? Fork the repo and submit a pull request.

1. Fork the repo


2. Create a new branch

git checkout -b feature-new-feature


3. Commit your changes

git commit -m "Added a new feature"


4. Push the branch

git push origin feature-new-feature


5. Create a pull request



📜 License

This project is licensed under the MIT License.
