import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmlink/presentation/screens/auth/splash_screen.dart';
import 'package:farmlink/presentation/screens/auth/welcome_screen.dart';
import 'package:farmlink/presentation/screens/auth/login_screen.dart';
import 'package:farmlink/presentation/screens/auth/signup_screen.dart';
import 'package:farmlink/presentation/screens/farmer/farmer_shell.dart';
import 'package:farmlink/presentation/screens/buyer/buyer_shell.dart';
import 'package:farmlink/presentation/screens/buyer/crop_detail_screen.dart';
import 'package:farmlink/presentation/screens/shared/chat_list_screen.dart';
import 'package:farmlink/presentation/screens/shared/order_detail_screen.dart';

import '../../domain/entities/crop.dart';
import '../../domain/entities/order.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/shared/chat_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // Auth redirect is handled by SplashScreen
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(
        path: '/login/:role',
        builder: (_, state) =>
            LoginScreen(role: state.pathParameters['role'] ?? 'farmer'),
      ),
      GoRoute(
        path: '/signup/:role',
        builder: (_, state) =>
            SignupScreen(role: state.pathParameters['role'] ?? 'farmer'),
      ),
      GoRoute(
        path: '/forgot-password/:role',
        builder: (context, state) {
          final role = state.pathParameters['role'] ?? 'buyer';
          return ForgotPasswordScreen(role: role);
        },
      ),
      GoRoute(
        path: '/farmer',
        builder: (_, __) => const FarmerShell(),
      ),
      GoRoute(
        path: '/buyer',
        builder: (_, __) => const BuyerShell(),
      ),
      GoRoute(
        path: '/crop-detail',
        builder: (_, state) {
          final crop = state.extra as Crop;
          return CropDetailScreen(crop: crop);
        },
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ChatDetailScreen(
            chatId: state.pathParameters['chatId']!,
            otherUid: extra['otherUid'] as String,
            otherName: extra['otherName'] as String,
            cropName: extra['cropName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/chats',
        builder: (_, __) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/order-detail',
        builder: (_, state) {
          final order = state.extra as Order;
          return OrderDetailScreen(order: order);
        },
      ),
    ],
  );
});