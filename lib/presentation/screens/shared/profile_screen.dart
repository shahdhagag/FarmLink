import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:farmlink/core/theme/app_theme.dart';

import '../../../data/services/auth_services.dart';
import '../../providers/app_provider.dart';
import '../../widgets/empty_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),

        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load profile',
          subtitle: e.toString(),
        ),
        data: (user) {
          if (user == null) {
            return const EmptyState(
              icon: Icons.person_off_rounded,
              title: 'Not logged in',
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Column(
              children: [
                // Avatar card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 32.h),
                  decoration: BoxDecoration(
                    color: user.isFarmer
                        ? AppColors.primary
                        : AppColors.secondary,
                    borderRadius: BorderRadius.circular(32.r),
                    boxShadow: [
                      BoxShadow(
                        color: (user.isFarmer
                            ? AppColors.primary
                            : AppColors.secondary)
                            .withOpacity(0.3),
                        blurRadius: 30.r,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48.r,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        user.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          user.role[0].toUpperCase() + user.role.substring(1),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        user.email,
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13.sp),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Details card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16.r,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: user.phone ?? 'Not set',
                      ),
                      const Divider(height: 1),
                      _ProfileTile(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: user.location ?? 'Not set',
                      ),
                      const Divider(height: 1),
                      _ProfileTile(
                        icon: Icons.calendar_today_rounded,
                        label: 'Member Since',
                        value: _formatDate(user.createdAt),
                      ),
                      if (user.rating > 0) ...[
                        const Divider(height: 1),
                        _ProfileTile(
                          icon: Icons.star_rounded,
                          label: 'Rating',
                          value:
                          '${user.rating.toStringAsFixed(1)} (${user.ratingCount} reviews)',
                          iconColor: AppColors.amber,
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Settings / Actions
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16.r,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(children: [
                    _ActionTile(
                      icon: Icons.edit_rounded,
                      label: 'Edit Profile',
                      onTap: () => _showEditDialog(context, ref, user.uid,
                          user.name, user.phone ?? ''),
                    ),
                    const Divider(height: 1),
                    _ActionTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'Change Password',
                      onTap: () => _sendPasswordReset(context, user.email),
                    ),
                    const Divider(height: 1),
                    _ActionTile(
                      icon: Icons.my_location_rounded,
                      label: 'Update My Location',
                      onTap: () => _updateLocation(context, ref, user.uid),
                    ),
                    const Divider(height: 1),
                    _ActionTile(
                      icon: Icons.logout_rounded,
                      label: 'Log Out',
                      iconColor: AppColors.error,
                      textColor: AppColors.error,
                      onTap: () => _logout(context, ref),
                    ),
                  ]),
                ),

                SizedBox(height: 120.h),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _updateLocation(BuildContext context, WidgetRef ref, String uid) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fetching location...')));
      }
      final locService = ref.read(locationServiceProvider);
      final position = await locService.getCurrentPosition();
      final address = await locService.getAddressFromPosition(position);

      await ref.read(firestoreServiceProvider).updateUser(uid, {
        'location': address,
        'lat': position.latitude,
        'lon': position.longitude,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location updated successfully!'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error updating location: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Log Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService().signOut();
      if (context.mounted) context.go('/welcome');
    }
  }

  Future<void> _sendPasswordReset(BuildContext context, String email) async {
    await AuthService().sendPasswordResetEmail(email);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password reset email sent!'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, String uid,
      String currentName, String currentPhone) {
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(text: currentPhone);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(firestoreServiceProvider).updateUser(uid, {
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
          const SizedBox(width: 14),
          // Wrap the text column in Expanded so it occupies only the available space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  // These two lines prevent the overflow error
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: textColor ?? AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textTertiary, size: 20),
    );
  }
}