import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:farmlink/core/theme/app_theme.dart';

import '../../../domain/entities/crop.dart';
import '../../../domain/entities/order.dart';
import '../../providers/app_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/fl_text_field.dart';

import '../../widgets/section_header.dart';
import '../../widgets/shimmer_card.dart';
import '../../widgets/status_badge.dart';

class FarmerOrdersTab extends ConsumerWidget {
  const FarmerOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    final ordersAsync = ref.watch(farmerOrdersProvider(user.uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Incoming Orders', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20.sp)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ordersAsync.when(
        loading: () => ListView.separated(
          padding: EdgeInsets.all(20.w),
          itemCount: 4,
          separatorBuilder: (_, __) => SizedBox(height: 14.h),
          itemBuilder: (_, __) => const ShimmerCard(height: 110),
        ),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load orders',
          subtitle: e.toString(),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox_rounded,
              title: 'No orders yet',
              subtitle: 'Orders from buyers will appear here.',
            );
          }

          final pending =
          orders.where((o) => o.status == 'pending').toList();
          final others =
          orders.where((o) => o.status != 'pending').toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                ref.invalidate(farmerOrdersProvider(user.uid)),
            child: ListView(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 120.h),
              physics: const BouncingScrollPhysics(),
              children: [
                if (pending.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Pending (${pending.length})',
                  ),
                  SizedBox(height: 14.h),
                  ...pending.asMap().entries.map((e) => Padding(
                    padding: EdgeInsets.only(bottom: 14.h),
                    child: _OrderCard(
                      order: e.value,
                      onTap: () =>
                          context.push('/order-detail', extra: e.value),
                    ).animate(delay: Duration(milliseconds: 60 * e.key)).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0),
                  )),
                  SizedBox(height: 20.h),
                ],
                if (others.isNotEmpty) ...[
                  SectionHeader(title: 'History (${others.length})'),
                  SizedBox(height: 14.h),
                  ...others.asMap().entries.map((e) => Padding(
                    padding: EdgeInsets.only(bottom: 14.h),
                    child: _OrderCard(
                      order: e.value,
                      onTap: () =>
                          context.push('/order-detail', extra: e.value),
                    ),
                  )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: order.status == 'pending'
                ? AppColors.warning.withOpacity(0.4)
                : AppColors.border.withOpacity(0.5),
            width: order.status == 'pending' ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                order.cropName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            StatusBadge(status: order.status),
          ]),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 6.h,
            children: [
              _Pill(Icons.person_outline_rounded, order.buyerName),
              _Pill(Icons.scale_rounded,
                  '${order.quantityKg.toStringAsFixed(1)} kg'),
              _Pill(Icons.currency_rupee_rounded,
                  '₹${order.totalAmount.toStringAsFixed(0)}'),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
            style: TextStyle(
                color: AppColors.textTertiary, fontSize: 11.sp),
          ),
          if (order.buyerNote != null && order.buyerNote!.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              padding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(children: [
                Icon(Icons.note_rounded,
                    size: 14.sp, color: AppColors.textTertiary),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    order.buyerNote!,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12.sp),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14.sp, color: AppColors.primary),
      SizedBox(width: 4.w),
      Text(text,
          style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500)),
    ]);
  }
}