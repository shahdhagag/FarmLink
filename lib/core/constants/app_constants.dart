class AppConstants {
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String cropsCollection = 'CropMain';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String ordersCollection = 'orders';
  static const String notificationsCollection = 'notifications';

  // Storage Paths
  static const String cropImagesPath = 'crop_images';
  static const String profileImagesPath = 'profile_images';

  // User Roles
  static const String roleFarmer = 'farmer';
  static const String roleBuyer = 'buyer';

  // Order Statuses
  static const String orderPending = 'pending';
  static const String orderAccepted = 'accepted';
  static const String orderRejected = 'rejected';
  static const String orderCompleted = 'completed';

  // Weather API
  static const String weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';
  static const String weatherApiKey = 'af2928389688d1e0d64e480cfe766d88';

  // Pagination
  static const int pageSize = 20;
}

class AppStrings {
  static const String appName = 'FarmLink';
  static const String tagline = 'From Farm to Table';
  static const String farmer = 'Farmer';
  static const String buyer = 'Buyer';

  // Auth
  static const String login = 'Log In';
  static const String signup = 'Sign Up';
  static const String logout = 'Logout';
  static const String email = 'Email Address';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';

  // Errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'No internet connection.';
  static const String locationError = 'Could not get location.';
}