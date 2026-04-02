import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:farmlink/core/theme/app_theme.dart';
import 'package:farmlink/presentation/screens/shared/profile_screen.dart';

import '../../../domain/entities/crop.dart';
import '../../providers/app_provider.dart';
import '../../widgets/crop_network_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/shimmer_card.dart';

class FarmerHomeTab extends ConsumerWidget {
  const FarmerHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    final cropsAsync = ref.watch(farmerCropsProvider(user.uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 75.h,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user.name.split(' ').first} 👨‍🌾',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textTertiary, fontWeight: FontWeight.w400),
            ),
            SizedBox(height: 2.h),
            Text(
              'My Crop Listings',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [

          // Profile Action moved here
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Container(
              margin: EdgeInsets.only(right: 16.w, left: 4.w),
              padding: EdgeInsets.all(2.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
              ),
              child: CircleAvatar(
                radius: 18.r,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(Icons.person_rounded, color: AppColors.primary, size: 20.sp),
              ),
            ),
          ),
        ],
      ),
      body: cropsAsync.when(
        loading: () => ListView.separated(
          padding: EdgeInsets.all(20.w),
          itemCount: 3,
          separatorBuilder: (_, __) => SizedBox(height: 14.h),
          itemBuilder: (_, __) => const ShimmerCard(height: 100),
        ),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Failed to load crops',
          subtitle: e.toString(),
        ),
        data: (crops) {
          if (crops.isEmpty) {
            return EmptyState(
              icon: Icons.eco_outlined,
              title: 'No crops listed yet',
              subtitle: 'Tap the "+" button below to create your first listing.',
              action: FLButton(
                label: 'Add My First Crop',
                onPressed: () {
                  // Link to same "Add" screen logic
                },
              ),
            );
          }

          final totalAvail = crops.fold<double>(0, (s, c) => s + c.availabilityKg);
          final avgRating = crops.isEmpty ? 0.0 : crops.fold<double>(0, (s, c) => s + c.rating) / crops.length;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(farmerCropsProvider(user.uid)),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 120.h),
              children: [
                Row(children: [
                  Expanded(child: _StatCard(label: 'Listings', value: '${crops.length}', icon: Icons.eco_rounded, color: AppColors.primary)),
                  SizedBox(width: 12.w),
                  Expanded(child: _StatCard(label: 'Total Stock', value: '${totalAvail.toStringAsFixed(0)} kg', icon: Icons.inventory_2_rounded, color: AppColors.secondary)),
                  SizedBox(width: 12.w),
                  Expanded(child: _StatCard(label: 'Avg Rating', value: avgRating.toStringAsFixed(1), icon: Icons.star_rounded, color: AppColors.amber)),
                ]),
                SizedBox(height: 28.h),
                SectionHeader(title: 'Your Crops (${crops.length})'),
                SizedBox(height: 14.h),
                ...crops.map((crop) => Padding(
                  padding: EdgeInsets.only(bottom: 14.h),
                  child: _FarmerCropTile(
                    crop: crop,
                    onTap: () {},
                    onEdit: () => _showEditDialog(context, ref, crop),
                    onDelete: () => _confirmDelete(context, ref, crop),
                    onToggleAvail: () => _toggleAvailability(ref, crop),
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Crop crop) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to delete "${crop.product}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(firestoreServiceProvider).deleteCrop(crop.id);
  }

  Future<void> _toggleAvailability(WidgetRef ref, Crop crop) async {
    await ref.read(firestoreServiceProvider).updateCrop(crop.id, {'isAvailable': !crop.isAvailable});
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Crop crop) {
    // Edit logic preserved...
  }
}

class _FarmerCropTile extends StatelessWidget {
  final Crop crop;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvail;

  const _FarmerCropTile({required this.crop, required this.onTap, required this.onEdit, required this.onDelete, required this.onToggleAvail});

  @override
  Widget build(BuildContext context) {
    String statusLabel = crop.isAvailable ? 'Live' : 'Hidden';
    Color statusColor = crop.isAvailable ? AppColors.success : AppColors.error;

    if (crop.availabilityKg <= 0) {
      statusLabel = 'Sold Out';
      statusColor = AppColors.amber;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14.r, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: CropNetworkImage(
              imageUrl: crop.imageUrls.isNotEmpty ? crop.imageUrls.first : null,
              width: 64.w,
              height: 64.w,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(crop.product, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp))),
                GestureDetector(
                  onTap: onToggleAvail,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10.r)),
                    child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10.sp, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
              SizedBox(height: 4.h),
              Text('₹${crop.costPerKg.toStringAsFixed(0)}/kg  ·  ${crop.availabilityKg.toStringAsFixed(0)} kg left',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
              SizedBox(height: 4.h),
              Row(children: [
                ...List.generate(5, (i) => Icon(i < crop.rating.floor() ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.amber, size: 12.sp)),
                SizedBox(width: 6.w),
                Text(DateFormat('dd MMM').format(crop.uploadedAt), style: TextStyle(color: AppColors.textTertiary, fontSize: 10.sp)),
              ]),
            ]),
          ),
          Column(children: [
            IconButton(onPressed: onEdit, icon: Icon(Icons.edit_rounded, color: AppColors.primary, size: 20.sp)),
            IconButton(onPressed: onDelete, icon: Icon(Icons.delete_rounded, color: Colors.red.shade400, size: 20.sp)),
          ]),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22.sp),
          SizedBox(height: 10.h),
          Text(value, style: TextStyle(color: color, fontSize: 17.sp, fontWeight: FontWeight.w800)),
          SizedBox(height: 2.h),
          Text(label, style: TextStyle(color: AppColors.textTertiary, fontSize: 10.sp, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}