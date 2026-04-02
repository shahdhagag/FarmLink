# FarmMate 🌱

**FarmMate** (also known as FarmLink) is a modern, direct-to-consumer agricultural marketplace designed to bridge the gap between farmers and buyers. It empowers farmers to list their fresh produce directly and allows buyers to purchase high-quality crops without intermediaries.

---

## 🚀 Features

### For Farmers 🚜

* **Crop Management:** Effortlessly list crops with detailed specifications including organic/hybrid certification, harvest dates, and high-quality images.
* **Real-time Order Management:** Track and respond to pending orders from buyers.
* **Localized Weather Forecast:** Integrated weather tab providing real-time conditions (Temp, Humidity, Wind) to help plan farm activities.
* **GPS Location Integration:** Automatically capture farm coordinates for accurate delivery and mapping.
* **Direct Communication:** Built-in chat system to negotiate and discuss details with potential buyers.

### For Buyers 🛒

* **Smart Discovery:** Search and filter crops by category, location, or name.
* **Detailed Product Insights:** View crop descriptions, "About the Produce" sections, and certified organic status.
* **Seamless Ordering:** Place orders with custom quantities and notes for the farmer.
* **Farm Mapping:** One-tap navigation to view the exact location of the farm on Google Maps.
* **Instant Messaging:** Secure chat interface to communicate directly with producers.

---

## 📸 UI Preview

### 🚜 Farmer Side

#### 🔐 Authentication

<p align="center">
  <img src="assets/screenshots/welcome.png" width="22%" />
  <img src="assets/screenshots/login_farmar.png" width="22%" />
  <img src="assets/screenshots/signupFarmar.png" width="22%" />
  <img src="assets/screenshots/forgotPassword.png" width="22%" />

</p>

#### 🏠 Home & Add Crop

<p align="center">
  <img src="assets/screenshots/farmer_home_tab.png" width="22%" />
 <img src="assets/screenshots/farmer_add_crop.png1" width="22%" />
 <img src="assets/screenshots/farmer_add_crop.png2" width="22%" />
    <img src="assets/screenshots/farmer_orders_list.png" width="22%" />

</p>

#### 📦 Orders & Chat

<p align="center">
  <img src="assets/screenshots/farmer_chat_list.png" width="22%" />
  <img src="assets/screenshots/farmer_weather_tab1.png" width="22%" />
  <img src="assets/screenshots/farmer_weather_tab2.png" width="22%" />
</p>

#### 🌦️ Weather



---

### 🛒 Buyer Side

#### 🔐 Authentication

<p align="center">
  <img src="assets/screenshots/buyerlogin.png" width="22%" />
  <img src="assets/screenshots/buyer_signup.png" width="22%" />
</p>

#### 🏪 Marketplace & Details

<p align="center">
  <img src="assets/screenshots/buyerHomeScreen.png" width="22%" />
  <img src="assets/screenshots/buyerCropDetails.png" width="22%" />
  <img src="assets/screenshots/buyerCROPdetailes2.png" width="22%" />
</p>

#### 🧾 Orders & Chat

<p align="center">
  <img src="assets/screenshots/buyerOrderScreen.png" width="22%" />
  <img src="assets/screenshots/buyerChatScreen.png" width="22%" />
</p>

#### 👤 Profile

<p align="center">
  <img src="assets/screenshots/buyerProfileScreen.png" width="22%" />
</p>

---

## 🛠️ Technologies Used

### **Frontend & Framework**

* **Flutter:** Multi-platform UI framework.
* **Riverpod:** Robust reactive state management.
* **GoRouter:** Declarative routing and navigation.
* **Flutter Animate:** For smooth, modern UI transitions.
* **ScreenUtil:** Responsive UI design across different device sizes.

### **Backend & Infrastructure**

* **Firebase Authentication:** Secure user sign-in and identity management.
* **Cloud Firestore:** Real-time NoSQL database for crops, orders, and chats.
* **Firebase Storage:** Scalable storage for produce images.

### **APIs & Services**

* **OpenWeather API:** Real-time weather data integration.
* **Geolocator & Geocoding:** GPS services for farm location and address conversion.
* **URL Launcher:** Integration with system maps and phone dialer.

---

## 🏗️ Architecture

The project follows a modular **Clean Architecture** pattern to ensure scalability and maintainability:

* **Core:** Global themes, constants, and utilities.
* **Domain:** Pure business logic and entities (User, Crop, Order, Message).
* **Data:** Implementation of repositories and external services (Firestore, Location).
* **Presentation:**

  * **Screens:** UI layers for Farmer and Buyer flows.
  * **Providers:** Riverpod state providers.
  * **Widgets:** Reusable UI components (Buttons, TextFields, Cards).


---

## 🎥 Demo Video

https://drive.google.com/file/d/14hNO3rjDGU7xC1DDiB5gmI3jOX9joaeg/view?usp=sharing

---

*Developed with ❤️ for the Agricultural Community.*
