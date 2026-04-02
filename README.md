# FarmMate 🌱

**FarmMate** (also known as FarmLink) is a modern, direct-to-consumer agricultural marketplace designed to bridge the gap between farmers and buyers. It empowers farmers to list their fresh produce directly and allows buyers to purchase high-quality crops without intermediaries.

## 🚀 Features

### For Farmers 🚜
- **Crop Management:** Effortlessly list crops with detailed specifications including organic/hybrid certification, harvest dates, and high-quality images.
- **Real-time Order Management:** Track and respond to pending orders from buyers.
- **Localized Weather Forecast:** Integrated weather tab providing real-time conditions (Temp, Humidity, Wind) to help plan farm activities.
- **GPS Location Integration:** Automatically capture farm coordinates for accurate delivery and mapping.
- **Direct Communication:** Built-in chat system to negotiate and discuss details with potential buyers.

### For Buyers 🛒
- **Smart Discovery:** Search and filter crops by category, location, or name.
- **Detailed Product Insights:** View crop descriptions, "About the Produce" sections, and certified organic status.
- **Seamless Ordering:** Place orders with custom quantities and notes for the farmer.
- **Farm Mapping:** One-tap navigation to view the exact location of the farm on Google Maps.
- **Instant Messaging:** Secure chat interface to communicate directly with producers.

---

## 🛠️ Technologies Used

### **Frontend & Framework**
- **Flutter:** Multi-platform UI framework.
- **Riverpod:** Robust reactive state management.
- **GoRouter:** Declarative routing and navigation.
- **Flutter Animate:** For smooth, modern UI transitions.
- **ScreenUtil:** Responsive UI design across different device sizes.

### **Backend & Infrastructure**
- **Firebase Authentication:** Secure user sign-in and identity management.
- **Cloud Firestore:** Real-time NoSQL database for crops, orders, and chats.
- **Firebase Storage:** Scalable storage for produce images.

### **APIs & Services**
- **OpenWeather API:** Real-time weather data integration.
- **Geolocator & Geocoding:** GPS services for farm location and address conversion.
- **URL Launcher:** Integration with system maps and phone dialer.

---

## 🏗️ Architecture

The project follows a modular **Clean Architecture** pattern to ensure scalability and maintainability:

- **Core:** Global themes, constants, and utilities.
- **Domain:** Pure business logic and entities (User, Crop, Order, Message).
- **Data:** Implementation of repositories and external services (Firestore, Location).
- **Presentation:**
    - **Screens:** UI layers for Farmer and Buyer flows.
    - **Providers:** Riverpod state providers.
    - **Widgets:** Reusable UI components (Buttons, TextFields, Cards).

---

## 📥 Getting Started

### Prerequisites
- Flutter SDK (v3.x)
- Firebase Account
- OpenWeather API Key

### Installation
1. **Clone the repo:**
   ```bash
   git clone https://github.com/yourusername/FarmMate.git
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Setup Firebase:**
   - Create a project on [Firebase Console](https://console.firebase.google.com/).
   - Add Android/iOS apps and download `google-services.json` or `GoogleService-Info.plist`.
   - Enable Firestore, Auth, and Storage.
4. **Configure API Keys:**
   - Update `lib/ApiKey.dart` with your OpenWeather API key.
5. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📸 UI Preview
- **Modern Glassmorphism:** Used in the Weather Tab for a premium feel.
- **Animated Interactions:** Smooth fade-ins and slide transitions throughout the app.
- **Accessibility:** High-contrast text and intuitive iconography for ease of use by all users.

---
*Developed with ❤️ for the Agricultural Community.*
