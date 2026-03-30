import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/firebase_options.dart';
import 'package:farmlink/src/pages/Home_pages/Buyer_HomeScreen/Buyer_Main_Home.dart';
import 'package:farmlink/src/pages/Home_pages/Farmers_HomeScreen/Farmers_Main_Home.dart';
import 'package:farmlink/src/pages/Landing_pages/welcome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize Firebase with your new options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FarmLinkApp());
}

class FarmLinkApp extends StatelessWidget {
  const FarmLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FarmLink',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
              color: Color.fromRGBO(0, 0, 0, 1.0),
              fontFamily: "Poppins-SemiBold"),
          bodySmall: TextStyle(
              fontSize: 12,
              color: Color.fromRGBO(255, 255, 255, 1.0),
              fontFamily: "Poppins-SemiBold"),
        ),
        elevatedButtonTheme: const ElevatedButtonThemeData(
          style: ButtonStyle(
            elevation: WidgetStatePropertyAll(11),
            backgroundColor: WidgetStatePropertyAll(
                Color.fromRGBO(51, 114, 51, 1.0)),
          ),
        ),
      ),
      home: const SplashScreen(), 
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 3. Wait for the first frame to be drawn before checking login
    // This prevents the "Context not ready" crash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    // 4. Give Firebase a moment to resolve the current user session
    await Future.delayed(const Duration(seconds: 2));

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _navigateTo(const welcome());
      return;
    }

    try {
      // 5. Fetch user role from your NEW Firestore project
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _navigateTo(const welcome());
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? userType = userData['role'];

      if (userType == "farmer") {
        _navigateTo(const FarmersMainHome());
      } else if (userType == "buyer") {
        _navigateTo(const BuyerMainHome());
      } else {
        _navigateTo(const welcome());
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      _navigateTo(const welcome());
    }
  }

  // Helper method for cleaner navigation
  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          color: Color.fromRGBO(51, 114, 51, 1.0),
        ),
      ),
    );
  }
}