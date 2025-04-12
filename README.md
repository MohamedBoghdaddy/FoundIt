# 📱 FoundIt @ MIU – Lost & Found Campus App

> A smart, secure, and student-only Flutter app to help MIU students report and recover lost or found items on campus.

---

## 🧾 Project Description

**FoundIt @ MIU** is a mobile application designed exclusively for students at **Misr International University (MIU)**. It helps them post, find, and recover lost and found items using Firebase for secure authentication and data management.

The app includes a **questionnaire-based matching system** that ensures items are only returned to their rightful owners after verification through structured answers and auto-ranking logic.

---

## 🔍 Advanced Matching Logic

1. **User Who Found an Item**:
   - Posts the item with: image, name, description, and MIU building location.
   - Fills out a **Finder Questionnaire** describing item traits and found details.

2. **User Who Lost an Item**:
   - Answers the same **Seeker Questionnaire**.
   - The app compares both sets of answers and calculates a **match score**.

3. **Matching Workflow**:
   - ❌ If the lost date > found date → request auto-declined.
   - 🏆 Highest scoring user sees the item image and confirms.
   - ✅ If confirmed, a private **chat system** opens for meetup coordination.
   - ❌ If denied, next top-matching user is notified.

---

## 🚀 Key Features

| Feature | Description |
|--------|-------------|
| 🔐 Firebase Auth | Student-only access (Google/email login) |
| 📍 Location Tagging | Identify exact MIU building where the item was found |
| 🧾 Questionnaire Forms | Structured questions for finders and seekers |
| 🧠 Auto Matching | Algorithm ranks answers and controls access to item |
| 📸 Image Upload | Photos help identify items visually |
| 💬 Chat System | Connect matched users privately to arrange return |
| 🔎 Search & Filter | Explore lost/found items by name or tag |
| 🌗 Dark Mode | Toggle between light and dark themes |
| 👤 Profile Management | View/edit/delete your posts |
| ✅ Mark as Returned | Close the item case after return |

---

## 🗂 Folder Structure

```
/lib
 ┣ /models
 ┃ ┗ item_model.dart
 ┣ /screens
 ┃ ┣ home_screen.dart
 ┃ ┣ post_item_screen.dart
 ┃ ┣ auth_screen.dart
 ┃ ┣ questionnaire_screen.dart
 ┃ ┣ chat_screen.dart
 ┗ /widgets
    ┣ item_card.dart
    ┣ custom_form_field.dart
    ┗ questionnaire_widget.dart
 ┣ /services
 ┃ ┣ firebase_service.dart
 ┃ ┣ auth_service.dart
 ┃ ┗ match_scoring_service.dart
 ┣ /utils
 ┃ ┗ constants.dart
 ┗ main.dart
```

---

## 🧠 Software Requirements Specification (SRS)

### ✅ Functional Requirements
- Firebase Authentication
- Item Posting (Lost/Found)
- Image Uploading
- Finder/Seeker Questionnaires
- Auto Matching & Scoring
- Chat System
- Item Search & Filtering
- User Profiles

### ⚙ Non-Functional Requirements
- Secure Firebase-based access
- Responsive, Material Design UI
- Works offline with Firebase sync
- Scalable and real-time backend

### 💻 Tools & Platforms
- **Flutter** (Mobile development)
- **Firebase** (Auth, Firestore, Storage)
- **Dart**
- Android / iOS Support

---

## 📅 Project Timeline – Gantt Chart

| Week | Task |
|------|------|
| **Week 1** | Project planning, UI wireframes, Firebase setup |
| **Week 2** | Firebase Auth, Post Item UI & Form |
| **Week 3** | Search, Filter, View Posts |
| **Week 4** | Questionnaire logic and scoring system |
| **Week 5** | Image reveal system + Chat system |
| **Week 6** | Final tests, debugging, UI polish, deployment |

---


## 📬 Contact

For inquiries or suggestions, please contact the development team at:  
📧 `foundit@miu.edu.eg`

---

## 📄 License

MIT License. See `LICENSE.md` for more info.
```
