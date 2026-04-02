import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:farmlink/core/theme/app_theme.dart';

import '../../../domain/entities/crop.dart';
import '../../providers/app_provider.dart';
import '../../widgets/crop_network_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_card.dart';

class BuyerHomeTab extends ConsumerStatefulWidget {
  const BuyerHomeTab({super.key});

  @override
  ConsumerState<BuyerHomeTab> createState() => _BuyerHomeTabState();
}

class _BuyerHomeTabState extends ConsumerState<BuyerHomeTab> {
  final _searchCtrl = TextEditingController();
  final _filters = ['All', 'Organic', 'Hybrid', 'Vegetables', 'Fruits'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentFilter = ref.watch(cropFilterProvider);
    final cropsAsync = ref.watch(filteredCropsProvider);
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(allCropsProvider(currentFilter)),
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: true,
              expandedHeight: 220.h,
              collapsedHeight: 120.h,
              backgroundColor: AppColors.surface,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                expandedTitleScale: 1,
                background: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_getGreetingIcon(), color: AppColors.amber, size: 16.sp),
                          SizedBox(width: 6.w),
                          Text(
                            'Good ${_greeting()},',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        user?.name.split(' ').first ?? 'Guest',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(100.h),
                child: Container(
                  color: AppColors.surface,
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      SizedBox(height: 12.h),
                      _buildFilterList(currentFilter),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ),
              ),
            ),

            cropsAsync.when(
              loading: () => _buildLoadingGrid(),
              error: (e, _) => const SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Connection Issue',
                  subtitle: 'Check your internet and try again.',
                ),
              ),
              data: (allCrops) {
                // INVENTORY LOGIC: Filter out items with 0 stock or marked as unavailable
                final crops = allCrops.where((c) => c.availabilityKg > 0 && c.isAvailable).toList();

                if (crops.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No produce available',
                      subtitle: 'Check back later for fresh harvests!',
                    ),
                  );
                }
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 100.h),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 0.64,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (_, i) => _EnhancedCropCard(
                        crop: crops[i],
                        onTap: () => context.push('/crop-detail', extra: crops[i]),
                      ).animate().fadeIn(duration: 300.ms, delay: (i % 6 * 50).ms).scaleXY(begin: 0.9, end: 1),
                      childCount: crops.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => ref.read(cropSearchProvider.notifier).state = v,
        decoration: InputDecoration(
          hintText: 'Search fresh produce...',
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20.sp),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              _searchCtrl.clear();
              ref.read(cropSearchProvider.notifier).state = '';
            },
          )
              : null,
          filled: true,
          fillColor: const Color(0xFFF1F4F6),
          contentPadding: EdgeInsets.symmetric(vertical: 0.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterList(String currentFilter) {
    return SizedBox(
      height: 40.h, // Increased slightly for better tap targets
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final category = _filters[i];
          final isSelected = currentFilter == category;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (selected) {
              // This updates the provider which triggers the filteredCropsProvider
              ref.read(cropFilterProvider.notifier).state = category;
            },
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12.sp,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border.withOpacity(0.5),
            ),
            showCheckmark: false, // Cleaner look
            elevation: isSelected ? 2 : 0,
          );
        },
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return SliverPadding(
      padding: EdgeInsets.all(20.w),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
              (_, __) => const ShimmerCard(height: 200),
          childCount: 4,
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  IconData _getGreetingIcon() {
    final h = DateTime.now().hour;
    if (h < 12) return Icons.wb_twilight_rounded;
    if (h < 17) return Icons.wb_sunny_rounded;
    return Icons.nights_stay_rounded;
  }
}

class _EnhancedCropCard extends StatelessWidget {
  final Crop crop;
  final VoidCallback onTap;

  const _EnhancedCropCard({required this.crop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                      child: CropNetworkImage(
                        imageUrl: crop.imageUrls.isNotEmpty ? crop.imageUrls.first : null,
                        height: double.infinity,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  if (crop.isOrganic)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text('ORGANIC', style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '₹${crop.costPerKg.toInt()}/kg',
                        style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(10.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop.product,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'By ${crop.farmerName}',
                          style: TextStyle(fontSize: 10.sp, color: AppColors.textTertiary),
                          maxLines: 1,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star_rounded, color: AppColors.amber, size: 14.sp),
                            Text(
                              ' ${crop.rating}',
                              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: crop.availabilityKg < 10 ? Colors.red.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            '${crop.availabilityKg.toInt()}kg left',
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: crop.availabilityKg < 10 ? Colors.red : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}