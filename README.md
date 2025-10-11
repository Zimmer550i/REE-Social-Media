---

# 💬 Ree — Social Media App

A modern, real-time **Social Media Application** built with **Flutter** for the frontend and **Node.js (Express + MongoDB)** for the backend.
It empowers users to **connect, share, and engage** through posts, group chats, and personalized feeds — all designed with a clean UI and reactive GetX state management.

---

## ✨ Features

* 👤 **User Authentication** — Secure login & signup with JWT
* 📝 **Post Creation** — Upload images, write captions, and express yourself
* ❤️ **Likes & Comments** — Engage with other users in real-time
* 💬 **Private & Group Chats** — Real-time messaging powered by WebSocket
* 🧠 **GetX State Management** — Reactive, modular, and lightning-fast
* 🖼️ **Profile Management** — Edit name, image, and bio instantly
* 🕊️ **News Feed** — Explore posts from friends and communities
* 🌙 **Dark Mode Ready** — Soothing UI for late-night scrolls
* 🔔 **Notifications System (Future Expansion)** — Stay updated in real-time
* 🚀 **Scalable API Architecture** — Built on Express + MongoDB for performance

---

## 📱 Screenshots

|              Login Screen              |              Feed Screen             |              Chat Screen             |
| :------------------------------------: | :----------------------------------: | :----------------------------------: |
| ![Login](assets/screenshots/login.png) | ![Feed](assets/screenshots/feed.png) | ![Chat](assets/screenshots/chat.png) |

---

## 🛠️ Built With

* **Flutter** — Cross-platform UI framework
* **Node.js + Express** — REST API backend
* **MongoDB + Mongoose** — Database & ORM
* **GetX** — State management, routing, dependency injection
* **Socket.io** — Real-time messaging
* **Dart** — Frontend language
* **JavaScript / TypeScript** — Backend language

---

## 🧩 Architecture Overview

```plaintext
lib/
├── controllers/      # GetX controllers for posts, users, and chats
├── models/           # Data models (User, Post, ChatMessage)
├── services/         # API calls and Socket.io handlers
├── views/            # Screens and UI components
├── utils/            # App colors, constants, helpers
└── main.dart         # App entry point

backend/
├── src/
│   ├── controllers/   # Business logic
│   ├── models/        # Mongoose schemas
│   ├── routes/        # Express routes (auth, post, chat)
│   ├── middleware/    # Auth & validation layers
│   └── config/        # DB & environment setup
└── server.js          # Express server entry
```

---

## 🚀 Getting Started

Follow these steps to run **Ree Social Media App** locally.

### 1. **Clone the repository**

```bash
git clone https://github.com/yourusername/Ree-Social-Media-App.git
cd Ree-Social-Media-App
```

---

### 2. **Flutter Setup**

```bash
cd flutter_app
flutter pub get
```

---

### 3. **Backend Setup**

```bash
cd backend
npm install
```

Setup `.env` file:

```env
PORT=5000
MONGO_URI=mongodb://localhost:27017/ree_app
JWT_SECRET=your_secret_key
```

Run the backend server:

```bash
npm run dev
```

Backend runs by default at:
👉 `http://localhost:5000/api`

---

### 4. **Connect Flutter App to Backend**

Update your base API URL in `lib/services/api_service.dart`:

```dart
const String baseUrl = "http://10.0.2.2:5000/api"; // for Android emulator
```

---

### 5. **Run the App**

```bash
flutter run
```

---

## 🔑 Environment Configuration

Use `.env` files for secure credentials (both frontend and backend).
In Flutter, you can use `flutter_dotenv` to manage environment variables.

---

## 📈 Future Improvements

* 🔔 Push notifications using Firebase Cloud Messaging
* 🎥 Video post uploads
* 💬 AI-powered smart replies in chat
* 📸 Story sharing with viewer insights
* 🌐 Multi-language support
* 🧠 Smart content recommendations

---

## 🤝 Contributing

Contributions are welcome! ❤️
Follow the standard GitHub flow:

```bash
# Create a new feature branch
git checkout -b feature/YourFeature

# Commit your changes
git commit -m 'Add some feature'

# Push to your branch
git push origin feature/YourFeature
```

Then open a Pull Request 🚀

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 💬 Connect with Me

* [LinkedIn](https://www.linkedin.com/in/s4k1l)
* [GitHub](https://github.com/S4K1L)
  
---

> **Crafted with ❤️ using Flutter, Node.js, and GetX — where social meets simplicity.**

---
