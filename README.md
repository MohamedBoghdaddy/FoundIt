# FoundIt @ MIU – Lost and Found Campus App

A smart, secure, student-only Flutter application that helps MIU students report, search for, and recover lost or found items on campus.

---

## Project Description

**FoundIt @ MIU** is a mobile application designed exclusively for students at **Misr International University (MIU)**. The app allows students to post lost or found items, search available reports, and recover belongings through a secure verification process.

FoundIt uses **Firebase Authentication**, **Cloud Firestore**, and **Firebase Storage** to provide secure login, real-time data management, image uploads, and private communication between matched users.

The main goal of the app is to make the lost-and-found process more organized, trustworthy, and efficient by using a questionnaire-based matching system. This system helps ensure that items are returned only to their rightful owners.

---

## Advanced Matching Logic

FoundIt includes a structured matching workflow that verifies ownership before revealing item details or opening communication.

### 1. Finder Workflow

A student who finds an item can create a found-item report by providing:

* Item image
* Item name
* Item description
* MIU building or campus location
* Answers to a finder questionnaire describing the item and where it was found

### 2. Seeker Workflow

A student who lost an item can submit a lost-item request by answering a seeker questionnaire. The answers are compared against the finder’s questionnaire to calculate a match score.

### 3. Matching Workflow

* If the lost date is later than the found date, the request is automatically declined.
* The user with the highest match score gets access to the item image for confirmation.
* If the user confirms the match, a private chat opens between the finder and the seeker.
* If the user denies the match, the next highest-ranking user is notified.
* Once the item is returned, the case can be marked as completed.

---

## Key Features

| Feature                   | Description                                                          |
| ------------------------- | -------------------------------------------------------------------- |
| Firebase Authentication   | Secure student-only login using Google or email authentication       |
| Location Tagging          | Allows users to tag the MIU building where an item was lost or found |
| Questionnaire Forms       | Structured questions for both finders and seekers                    |
| Auto Matching and Scoring | Ranks possible owners based on questionnaire similarity              |
| Image Upload              | Supports item photos to help users identify belongings               |
| Image Reveal Logic        | Reveals item images only after a strong questionnaire match          |
| Private Chat              | Enables matched users to coordinate item return securely             |
| Search and Filter         | Allows users to search and filter lost or found items                |
| Dark Mode                 | Supports both light and dark themes                                  |
| Profile Management        | Users can view, edit, and delete their own posts                     |
| Mark as Returned          | Allows users to close a case after the item is returned              |

---

## Folder Structure

```text
/lib
 ┣ /models
 ┃ ┗ item_model.dart
 ┣ /screens
 ┃ ┣ auth_screen.dart
 ┃ ┣ home_screen.dart
 ┃ ┣ post_item_screen.dart
 ┃ ┣ questionnaire_screen.dart
 ┃ ┗ chat_screen.dart
 ┣ /services
 ┃ ┣ auth_service.dart
 ┃ ┣ firebase_service.dart
 ┃ ┗ match_scoring_service.dart
 ┣ /utils
 ┃ ┗ constants.dart
 ┣ /widgets
 ┃ ┣ custom_form_field.dart
 ┃ ┣ item_card.dart
 ┃ ┗ questionnaire_widget.dart
 ┗ main.dart
```

---

## Software Requirements Specification

### Functional Requirements

The application should allow users to:

* Register and log in securely using Firebase Authentication
* Post lost or found items
* Upload images for item reports
* Add item descriptions and campus location details
* Complete finder and seeker questionnaires
* Automatically match lost-item requests with found-item reports
* Rank matches using a scoring algorithm
* Search and filter item posts
* Chat privately after a successful match
* Manage user profiles and personal posts
* Mark returned items as completed

### Non-Functional Requirements

The application should provide:

* Secure access using Firebase Authentication
* Real-time database updates through Cloud Firestore
* Reliable image storage using Firebase Storage
* A responsive and user-friendly Material Design interface
* Support for both Android and iOS
* Scalable data structure for future campus expansion
* Offline support through Firebase synchronization where applicable

---

## Tools and Technologies

| Tool                     | Purpose                                       |
| ------------------------ | --------------------------------------------- |
| Flutter                  | Cross-platform mobile application development |
| Dart                     | Main programming language                     |
| Firebase Authentication  | User login and access control                 |
| Cloud Firestore          | Real-time database                            |
| Firebase Storage         | Image upload and storage                      |
| Android Studio / VS Code | Development environment                       |
| Android / iOS            | Target mobile platforms                       |

---

## Project Timeline

| Week   | Task                                                              |
| ------ | ----------------------------------------------------------------- |
| Week 1 | Project planning, UI wireframes, and Firebase setup               |
| Week 2 | Firebase Authentication, item posting UI, and form implementation |
| Week 3 | Search, filtering, and item listing screens                       |
| Week 4 | Questionnaire logic and match-scoring system                      |
| Week 5 | Image reveal logic and private chat system                        |
| Week 6 | Testing, debugging, UI polish, and deployment preparation         |

---

## Future Enhancements

* Admin dashboard for managing reports and flagged posts
* Push notifications for match updates and chat messages
* QR code verification for item handover
* Improved AI-based image similarity matching
* Analytics dashboard for common lost-item locations
* Support for multiple university campuses

---

## Contact

For inquiries or suggestions, please contact the development team at:

`foundit@miu.edu.eg`

---

## License

This project is licensed under the MIT License. See `LICENSE.md` for more information.
