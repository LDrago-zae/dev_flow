# 📱 DevFlow – Project & Task Management App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge\&logo=flutter\&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge\&logo=dart\&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge\&logo=supabase\&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge\&logo=firebase\&logoColor=black)
![Mapbox](https://img.shields.io/badge/Mapbox-000000?style=for-the-badge\&logo=mapbox\&logoColor=white)

**A powerful offline-first project & task management application built with Flutter.**

[Features](#-features) • [Screenshots](#-screenshots) • [Installation](#-installation) • [Architecture](#-architecture) • [Technologies](#-technologies)

</div>

---

## 🎯 Overview

DevFlow is a comprehensive **Trello-style project and task management application** featuring **offline-first architecture**, **real-time collaboration**, **advanced tracking**, and **interactive maps**.
Built with **Flutter + Supabase**, it synchronizes seamlessly while remaining fully usable offline.

---

## ✨ Features

### 📊 Project Management

* Full **CRUD** with offline support
* **Custom cover images** via Supabase Storage
* **Project templates** (Design Sprint, Product Launch)
* **Auto progress tracking**
* **Color-coded projects**
* **Team collaboration & sharing**
* **File attachments** (Images, PDFs, Documents)

### ✅ Advanced Task Management

* Rich task creation (title, date, time, description, location)
* Task **assignments** with notifications
* **Mapbox-powered** location tagging
* **Recurring tasks** (daily → yearly)
* **Subtasks** checklist
* **Built-in time tracking timer**
* Swipe-to-delete & smart alerts

### 🎨 View Modes

* **List View** with expand/collapse
* **Kanban Board** with drag-and-drop
* **Filtering:** All / Ongoing / Completed
* Quick **view toggle**

### 🗺️ Location Features

* Full-screen **Mapbox GL maps**
* **Location puck** with accuracy ring
* Preview maps in task details
* Human-readable address display

### 🔄 Real-Time Sync

* Supabase Realtime over WebSocket
* Optimistic UI for instant feedback
* Auto reconnect
* Multi-user editing + conflict resolution

### 💾 Offline-First Architecture

* **SQLite local storage**
* Pending changes queue
* Background syncing
* Conflict handling
* Smart caching

### ⏱️ Time Tracking

* Per-task timers
* Live duration counter
* Auto-continue after restart
* History of time entries
* Project-level aggregation

### 🔔 Notifications

* **FCM Push Notifications**
* **In-app toasts** (success/error/loading)

### 👥 Collaboration

* Add/remove members
* Avatar display
* Permission control
* Assignment notifications

### 🎨 UI/UX Excellence

* Polished **dark theme**
* Smooth animations
* Gradient backgrounds
* Micro-interactions
* Pull-to-refresh
* Keyboard handling

---

## 📱 Screenshots

> *(Add screenshots here)*

---

## 🏗️ Architecture

### Design Patterns

* Repository Pattern
* Offline-first model
* Optimistic updates
* Stream-based reactive programming
* Clean separation (Model → Service → View)

### Project Structure

```
lib/
├── core/
│   ├── constants/
│   └── utils/
├── data/
│   ├── local/
│   ├── models/
│   └── repositories/
├── presentation/
│   ├── dialogs/
│   ├── views/
│   └── widgets/
├── services/
├── routes/
├── firebase_options.dart
└── main.dart
```

---

## 🛠️ Technologies

### Frontend

* Flutter 3.x
* Dart
* Material Design 3

### Backend

* Supabase (PostgreSQL, Auth, Realtime, Storage)
* SQLite (offline DB)

### Services & APIs

* Firebase Cloud Messaging
* Mapbox GL
* Supabase Realtime
* File storage buckets

---

## 🚀 Installation

### Prerequisites

* Flutter 3.x
* Dart 3.x
* Android Studio / Xcode
* Supabase account
* Firebase project
* Mapbox access token

### Steps

#### 1. Clone Repository

```bash
git clone https://github.com/Ldrago-R/devflow.git
cd devflow
```

#### 2. Install Dependencies

```bash
flutter pub get
```

#### 3. Configure Supabase

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

#### 4. Configure Firebase

Run:

```bash
flutterfire configure
```

#### 5. Add Mapbox Token

#### 6. Run App

```bash
flutter run
```

---

## 📋 Database Schema

### Projects Table

* id (UUID)
* title
* description
* status
* progress
* image_path
* assigned_user_id
* user_id
* created_date

### Tasks Table

* id
* title
* date/time
* completion status
* assigned_user_id
* project_id
* location fields
* recurrence pattern

### Subtasks Table

* id
* parent_task_id
* title
* completed
* owner_id

---

## 🔐 Security

* Full **Row-Level Security (RLS)**
* Auth-based data access
* Secure token handling
* Protected API keys

---

## 🤝 Contributing

1. Fork repo
2. Create branch
3. Commit changes
4. Push
5. Open PR

---

## 📄 License

MIT License © Zaeem Imtiaz (Ldrago-R)

---

## 👨‍💻 Author

**Zaeem Imtiaz**
📧 Email: **[zaeemimtiaz904@gmail.com](mailto:zaeemimtiaz904@gmail.com)**
🐙 GitHub: **@Ldrago-R**
🔗 LinkedIn: *(https://www.linkedin.com/in/zaeem-imtiaz-8b9baa24a/)*

---

## ⭐ Support

If you find DevFlow useful, **please star the repo!**
Your support helps the project grow.

---

Made with ❤️ using Flutter
