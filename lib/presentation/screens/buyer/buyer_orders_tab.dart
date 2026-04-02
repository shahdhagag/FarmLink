import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:farmlink/core/theme/app_theme.dart';

import '../../providers/app_provider.dart';

class BuyerOrdersTab extends ConsumerWidget {
  const BuyerOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const Center(child: CircularProgressIndicator());

    final ordersAsync = ref.watch(buyerOrdersProvider(user.uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Orders', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20.sp)),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 72.sp, color: AppColors.textTertiary),
                  SizedBox(height: 20.h),
                  Text('No orders yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16.sp)),
                  SizedBox(height: 8.h),
                  Text('Your orders will appear here', style: TextStyle(color: AppColors.textTertiary, fontSize: 13.sp)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 120.h),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Container(
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(color: AppColors.border.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16.r,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(22.r),
                  child: InkWell(
                    onTap: () => context.push('/order-detail', extra: order),
                    borderRadius: BorderRadius.circular(22.r),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 24.sp),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order.cropName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp)),
                                SizedBox(height: 4.h),
                                Text('Farmer: ${order.farmerName}', style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                                SizedBox(height: 2.h),
                                Text(DateFormat('dd MMM yyyy').format(order.createdAt),
                                    style: TextStyle(fontSize: 11.sp, color: AppColors.textTertiary)),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${order.totalAmount.toStringAsFixed(0)}',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 16.sp)),
                              SizedBox(height: 8.h),
                              _StatusChip(status: order.status),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.textTertiary;
    if (status == 'pending') color = AppColors.amber;
    if (status == 'accepted') color = AppColors.success;
    if (status == 'rejected') color = AppColors.error;
    if (status == 'completed') color = AppColors.primary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.w800),
      ),
    );
  }
}