import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:url_launcher/url_launcher.dart';
import 'package:farmlink/core/theme/app_theme.dart';

import '../../../domain/entities/order.dart';
import '../../providers/app_provider.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/info_tile.dart';

class OrderDetailScreen extends ConsumerWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isFarmer = user?.isFarmer ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18.sp)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 120.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(28.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 24.r,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.cropName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 8.h,
                    children: [
                      _HeroPill(
                          '${order.quantityKg.toStringAsFixed(1)} kg',
                          Icons.scale_rounded),
                      _HeroPill(
                          '₹${order.totalAmount.toStringAsFixed(0)}',
                          Icons.currency_rupee_rounded),
                      _HeroPill(
                          order.status[0].toUpperCase() +
                              order.status.substring(1),
                          Icons.info_outline_rounded),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 28.h),

            // Details card
            _Section(
              title: 'Order Info',
              children: [
                InfoTile(
                  icon: Icons.tag_rounded,
                  label: 'Order ID',
                  value: order.id.substring(0, 8).toUpperCase(),
                ),
                const Divider(),
                InfoTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Placed On',
                  value: DateFormat('dd MMM yyyy, hh:mm a')
                      .format(order.createdAt),
                ),
                const Divider(),
                InfoTile(
                  icon: Icons.scale_rounded,
                  label: 'Quantity',
                  value: '${order.quantityKg.toStringAsFixed(2)} kg',
                ),
                const Divider(),
                InfoTile(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Price per kg',
                  value: '₹${order.pricePerKg.toStringAsFixed(2)}',
                ),
                const Divider(),
                InfoTile(
                  icon: Icons.receipt_rounded,
                  label: 'Total Amount',
                  value: '₹${order.totalAmount.toStringAsFixed(2)}',
                ),
                if (order.buyerNote != null && order.buyerNote!.isNotEmpty) ...[
                  const Divider(),
                  InfoTile(
                    icon: Icons.note_rounded,
                    label: 'Buyer Note',
                    value: order.buyerNote!,
                  ),
                ],
              ],
            ),

            SizedBox(height: 20.h),

            // Parties card
            _Section(
              title: isFarmer ? 'Buyer Details' : 'Farmer Details',
              children: [
                InfoTile(
                  icon: Icons.person_rounded,
                  label: isFarmer ? 'Buyer Name' : 'Farmer Name',
                  value: isFarmer ? order.buyerName : order.farmerName,
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Track Order Map Button
            FLButton(
              label: isFarmer ? 'Track Buyer on Map' : 'Track Order on Map',
              icon: const Icon(Icons.map_rounded, color: Colors.white, size: 18),
              onPressed: () => _trackOnMap(context, isFarmer),
            ),

            // Farmer actions
            if (isFarmer && order.status == 'pending') ...[
              SizedBox(height: 24.h),
              Row(children: [
                Expanded(
                  child: FLButton(
                    label: 'Reject',
                    color: AppColors.error,
                    onPressed: () => _updateStatus(context, ref, 'rejected'),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: FLButton(
                    label: 'Accept',
                    onPressed: () => _updateStatus(context, ref, 'accepted'),
                  ),
                ),
              ]),
            ],

            if (isFarmer && order.status == 'accepted') ...[
              SizedBox(height: 24.h),
              FLButton(
                label: 'Mark as Completed',
                onPressed: () => _updateStatus(context, ref, 'completed'),
                icon: const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(
      BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateOrderStatus(order.id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Order $status'),
          backgroundColor: status == 'accepted' || status == 'completed'
              ? AppColors.success
              : AppColors.error,
        ));
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _trackOnMap(BuildContext context, bool isFarmer) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Locating...')));
      }

      double? lat;
      double? lon;
      String? fallbackLocation;

      if (isFarmer) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(order.buyerUid).get();
        if (doc.exists) {
          final data = doc.data()!;
          lat = (data['lat'] as num?)?.toDouble();
          lon = (data['lon'] as num?)?.toDouble();
          fallbackLocation = data['location'] as String?;
        }
      } else {
        final doc = await FirebaseFirestore.instance.collection('CropMain').doc(order.cropId).get();
        if (doc.exists) {
          final data = doc.data()!;
          lat = (data['lat'] as num?)?.toDouble();
          lon = (data['lon'] as num?)?.toDouble();
          fallbackLocation = data['Location'] as String?;
        }
      }

      Uri uri;
      if (lat != null && lon != null && lat != 0.0 && lon != 0.0) {
        uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
      } else if (fallbackLocation != null && fallbackLocation.isNotEmpty) {
        uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(fallbackLocation)}');
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not provided yet.')));
        }
        return;
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open map app.')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error locating: $e')));
      }
    }
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _HeroPill(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 14.sp),
        SizedBox(width: 5.w),
        Text(label,
            style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
      SizedBox(height: 14.h),
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    ]);
  }
}