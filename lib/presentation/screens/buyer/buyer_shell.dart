import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:badges/badges.dart' as badges;

import 'package:farmlink/core/theme/app_theme.dart';
import 'package:farmlink/presentation/screens/buyer/buyer_home_tab.dart';
import 'package:farmlink/presentation/screens/buyer/buyer_orders_tab.dart';
import 'package:farmlink/presentation/screens/shared/chat_list_screen.dart';
import 'package:farmlink/presentation/screens/shared/profile_screen.dart';

import '../../providers/app_provider.dart';

class BuyerShell extends ConsumerStatefulWidget {
  const BuyerShell({super.key});

  @override
  ConsumerState<BuyerShell> createState() => _BuyerShellState();
}

class _BuyerShellState extends ConsumerState<BuyerShell> {
  int _currentIndex = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = const [
      BuyerHomeTab(),
      BuyerOrdersTab(),
      ChatListScreen(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final unreadCount = _getUnreadCount(ref, userAsync.value?.uid ?? '');

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
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
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
            child: GNav(
              rippleColor: AppColors.secondaryContainer,
              hoverColor: AppColors.secondary.withOpacity(0.1),
              gap: 8.w,
              activeColor: AppColors.secondary,
              iconSize: 24.sp,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              duration: const Duration(milliseconds: 300),
              tabBackgroundColor: AppColors.secondary.withOpacity(0.15),
              color: AppColors.textTertiary,
              textStyle: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
              tabs: [
                const GButton(icon: Icons.storefront_rounded, text: 'Market'),
                const GButton(icon: Icons.receipt_long_rounded, text: 'Orders'),
                GButton(
                  icon: Icons.chat_bubble_rounded,
                  text: 'Chat',
                  leading: unreadCount > 0
                      ? badges.Badge(
                          badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.error),
                          badgeContent: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                          ),
                          child: Icon(
                            Icons.chat_bubble_rounded,
                            color: _currentIndex == 2 ? AppColors.secondary : AppColors.textTertiary,
                            size: 22.sp,
                          ),
                        )
                      : null,
                ),
                const GButton(icon: Icons.person_rounded, text: 'Profile'),
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

  int _getUnreadCount(WidgetRef ref, String uid) {
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

  void _onTap(int index) => setState(() => _currentIndex = index);
}


