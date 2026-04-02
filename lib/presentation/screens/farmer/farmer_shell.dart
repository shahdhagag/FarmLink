import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:badges/badges.dart' as badges;

import 'package:farmlink/core/theme/app_theme.dart';
import 'package:farmlink/presentation/screens/farmer/farmer_home_tab.dart';
import 'package:farmlink/presentation/screens/farmer/farmer_orders_tab.dart';
import 'package:farmlink/presentation/screens/shared/chat_list_screen.dart';
import 'package:farmlink/presentation/screens/shared/profile_screen.dart';

import '../../providers/app_provider.dart';
import 'Farmer_weather_tab.dart';
import 'add_crop_screen.dart';

class FarmerShell extends ConsumerStatefulWidget {
  const FarmerShell({super.key});

  @override
  ConsumerState<FarmerShell> createState() => _FarmerShellState();
}

class _FarmerShellState extends ConsumerState<FarmerShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    FarmerHomeTab(),
    FarmerAddTab(),
    FarmerOrdersTab(),
    FarmerWeatherTab(),
    ChatListScreen(),
    // ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final unread = _getUnread(ref, userAsync.value?.uid ?? '');

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 24.r,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
            child: GNav(
              rippleColor: AppColors.primary.withOpacity(0.2),
              hoverColor: AppColors.primary.withOpacity(0.1),
              gap: 6.w,
              activeColor: AppColors.primary,
              iconSize: 22.sp,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              duration: const Duration(milliseconds: 300),
              tabBackgroundColor: AppColors.primary.withOpacity(0.15),
              color: AppColors.textTertiary,
              textStyle: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
              tabs: [
                const GButton(icon: Icons.home_rounded, text: 'Home'),
                const GButton(icon: Icons.add_circle_rounded, text: 'Add'),
                const GButton(icon: Icons.receipt_long_rounded, text: 'Orders'),
                const GButton(icon: Icons.cloud_rounded, text: 'Weather'),
                GButton(
                  icon: Icons.chat_bubble_rounded,
                  text: 'Chat',
                  leading: unread > 0
                      ? badges.Badge(
                          badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.error),
                          badgeContent: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                          ),
                          child: Icon(
                            Icons.chat_bubble_rounded,
                            color: _currentIndex == 4 ? AppColors.primary : AppColors.textTertiary,
                            size: 22.sp,
                          ),
                        )
                      : null,
                ),
                //const GButton(icon: Icons.person_rounded, text: 'Profile'),
              ],
              selectedIndex: _currentIndex,
              onTabChange: _onTap,
            ),
          ),
        ),
      ),
      ),
    ));
  }

  int _getUnread(WidgetRef ref, String uid) {
    if (uid.isEmpty) return 0;
    final chats = ref.watch(userChatsProvider(uid));
    return chats.whenOrNull(data: (rooms) {
      int total = 0;
      for (final r in rooms) {
        total += r.unreadCount[uid] ?? 0;
      }
      return total;
    }) ??
        0;
  }

  void _onTap(int i) => setState(() => _currentIndex = i);
}

