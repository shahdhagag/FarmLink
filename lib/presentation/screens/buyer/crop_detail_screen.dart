import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:farmlink/core/theme/app_theme.dart';

import '../../../domain/entities/crop.dart';
import '../../../domain/entities/order.dart' as ent;
import '../../providers/app_provider.dart';
import '../../widgets/crop_network_image.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/info_tile.dart';

class CropDetailScreen extends ConsumerStatefulWidget {
  final Crop crop;
  const CropDetailScreen({super.key, required this.crop});

  @override
  ConsumerState<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends ConsumerState<CropDetailScreen> {
  final _qtyCtrl = TextEditingController(text: '1');
  final _noteCtrl = TextEditingController();
  bool _ordering = false;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(firestoreServiceProvider).incrementViewCount(widget.crop.id));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Crop get crop => widget.crop;

  // ── Logic Methods ──────────────────────────────────────────────────────────

  Future<void> _startChat() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      _showSnackBar('Please login to chat with the farmer', AppColors.amber);
      return;
    }

    try {
      // Show loading overlay if needed, but usually this is fast
      final chatId =
          await ref.read(firestoreServiceProvider).getOrCreateChatRoom(
                currentUid: user.uid,
                currentName: user.name,
                otherUid: crop.farmerUid,
                otherName: crop.farmerName,
                cropId: crop.id,
                cropName: crop.product,
              );

      if (!mounted) return;

      context.push('/chat/$chatId', extra: {
        'otherUid': crop.farmerUid,
        'otherName': crop.farmerName,
        'cropName': crop.product,
      });
    } catch (e) {
      _showSnackBar('Could not start chat: $e', AppColors.error);
    }
  }

  Future<void> _placeOrder() async {
    final qty = double.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0) {
      _showSnackBar('Enter a valid quantity', AppColors.error);
      return;
    }
    if (qty > crop.availabilityKg) {
      _showSnackBar(
          'Only ${crop.availabilityKg.toInt()} kg available', AppColors.amber);
      return;
    }

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _ordering = true);
    try {
      final order = ent.Order(
        id: '',
        cropId: crop.id,
        cropName: crop.product,
        farmerUid: crop.farmerUid,
        farmerName: crop.farmerName,
        buyerUid: user.uid,
        buyerName: user.name,
        quantityKg: qty,
        pricePerKg: crop.costPerKg,
        totalAmount: qty * crop.costPerKg,
        status: 'pending',
        buyerNote:
            _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreServiceProvider).placeOrder(order);

      if (!mounted) return;
      context.pop(); // Close order sheet
      _showSnackBar(
          'Order placed! Waiting for farmer response.', AppColors.success);
    } catch (e) {
      _showSnackBar('Failed: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _ordering = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openMap() async {
    final lat = crop.lat;
    final lon = crop.lon;
    Uri uri;

    if (lat != null && lon != null && lat != 0.0) {
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    } else {
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(crop.location)}');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showOrderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderBottomSheet(
        crop: crop,
        qtyCtrl: _qtyCtrl,
        noteCtrl: _noteCtrl,
        onPlace: _placeOrder,
        isLoading: _ordering,
      ),
    );
  }

  // ── Build UI ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final images = crop.imageUrls.isEmpty ? <String>[] : crop.imageUrls;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 380.h,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.primary,
                leadingWidth: 70.w,
                leading: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 40.r,
                        width: 40.r,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: IconButton(
                          onPressed: () => context.pop(),
                          icon: Icon(Icons.chevron_left_rounded,
                              color: Colors.white, size: 24.sp),
                        ),
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      images.isNotEmpty
                          ? PageView.builder(
                              onPageChanged: (i) =>
                                  setState(() => _imageIndex = i),
                              itemCount: images.length,
                              itemBuilder: (_, i) => CropNetworkImage(
                                imageUrl: images[i],
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              color: AppColors.primaryContainer,
                              child: Icon(Icons.eco_rounded,
                                  color: AppColors.primary, size: 80.sp),
                            ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [Colors.black54, Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0, -30, 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFB),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32.r)),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(crop.product,
                                      style: TextStyle(
                                          fontSize: 26.sp,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textPrimary)),
                                  SizedBox(height: 8.h),
                                  _modernChip(
                                      crop.isOrganic
                                          ? 'Organic Certified'
                                          : 'Conventional',
                                      crop.isOrganic
                                          ? AppColors.success
                                          : AppColors.secondary,
                                      Icons.verified_rounded),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 12.h),
                              decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                        color:
                                            AppColors.primary.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ]),
                              child: Column(
                                children: [
                                  Text('₹${crop.costPerKg.toInt()}',
                                      style: TextStyle(
                                          fontSize: 22.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white)),
                                  Text('per kg',
                                      style: TextStyle(
                                          fontSize: 10.sp,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        _buildStatsRow(),
                        SizedBox(height: 32.h),
                        Text('About this produce',
                            style: TextStyle(
                                fontSize: 18.sp, fontWeight: FontWeight.w800)),
                        SizedBox(height: 12.h),
                        Text(
                            crop.description.isNotEmpty
                                ? crop.description
                                : "Freshly harvested produce directly from the farm. Quality guaranteed with natural farming practices.",
                            style: TextStyle(
                                fontSize: 15.sp,
                                color: AppColors.textSecondary,
                                height: 1.5)),
                        SizedBox(height: 32.h),
                        _sectionTitle('Specifications'),
                        _buildSpecCard(),
                        SizedBox(height: 20.h),
                        FLButton(
                          label: 'View Farm Location',
                          onPressed: _openMap,
                          color: Colors.white,
                          textColor: AppColors.primary,
                          icon: const Icon(Icons.map_outlined,
                              color: AppColors.primary),
                        ),
                        SizedBox(height: 32.h),
                        _sectionTitle('Meet the Farmer'),
                        _buildFarmerCard(),
                        SizedBox(height: 120.h),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .moveY(begin: 20, end: 0),
                  ),
                ),
              ),
            ],
          ),

          // Floating Action Bottom Bar
          _buildBottomAction(context),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.star_rounded, AppColors.amber, crop.rating.toString(),
              'Rating'),
          _verticalDivider(),
          _statItem(Icons.remove_red_eye_rounded, AppColors.primary,
              crop.viewCount.toString(), 'Views'),
          _verticalDivider(),
          _statItem(
              Icons.timer_outlined, AppColors.secondary, '2 days', 'Delivery'),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, Color color, String val, String label) {
    return Column(
      children: [
        Row(children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 4.w),
          Text(val,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp))
        ]),
        Text(label,
            style: TextStyle(fontSize: 11.sp, color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _verticalDivider() =>
      Container(height: 30.h, width: 1, color: AppColors.border);

  Widget _buildSpecCard() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border.withOpacity(0.5))),
      child: Column(
        children: [
          InfoTile(
              icon: Icons.inventory_2_outlined,
              label: 'Current Stock',
              value: '${crop.availabilityKg.toInt()} kg'),
          const Divider(height: 30),
          InfoTile(
              icon: Icons.calendar_today_outlined,
              label: 'Harvest Date',
              value: DateFormat('dd MMM yyyy').format(crop.harvestDate)),
          const Divider(height: 30),
          InfoTile(
              icon: Icons.place_outlined,
              label: 'Origin',
              value: crop.location),
        ],
      ),
    );
  }

  Widget _buildFarmerCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
                crop.farmerName.isNotEmpty
                    ? crop.farmerName[0].toUpperCase()
                    : 'F',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(crop.farmerName,
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.bold)),
                Text('Trusted Seller',
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          _circleAction(Icons.phone_in_talk_rounded, AppColors.primary,
              () => launchUrl(Uri.parse('tel:${crop.farmerPhone}'))),
          SizedBox(width: 10.w),
          _circleAction(Icons.chat_bubble_rounded, AppColors.secondary,
              _startChat), // RE-ADDED CHAT LOGIC
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5))
            ]),
        child: Row(
          children: [
            _circleAction(Icons.chat_outlined, AppColors.textPrimary,
                _startChat), // RE-ADDED CHAT LOGIC
            SizedBox(width: 16.w),
            Expanded(
              child: FLButton(
                label: crop.isExpired ? 'Unavailable' : 'Order Now',
                onPressed: crop.isExpired ? null : _showOrderSheet,
                color: crop.isExpired ? Colors.grey : AppColors.primary,
                icon: const Icon(Icons.shopping_cart_checkout_rounded,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(title,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)));

  Widget _circleAction(IconData icon, Color color, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22.sp)),
      );

  Widget _modernChip(String label, Color color, IconData icon) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 6.w),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11.sp, fontWeight: FontWeight.bold))
        ]),
      );
}

class OrderBottomSheet extends StatefulWidget {
  final Crop crop;
  final TextEditingController qtyCtrl;
  final TextEditingController noteCtrl;
  final Future<void> Function() onPlace;
  final bool isLoading;

  const OrderBottomSheet(
      {super.key,
      required this.crop,
      required this.qtyCtrl,
      required this.noteCtrl,
      required this.onPlace,
      required this.isLoading});

  @override
  State<OrderBottomSheet> createState() => _OrderBottomSheetState();
}

class _OrderBottomSheetState extends State<OrderBottomSheet> {
  late double _total;
  bool _localIsLoading = false;

  @override
  void initState() {
    super.initState();
    _calculate();
    widget.qtyCtrl.addListener(_calculate);
  }

  @override
  void dispose() {
    widget.qtyCtrl.removeListener(_calculate);
    super.dispose();
  }

  void _calculate() {
    final q = double.tryParse(widget.qtyCtrl.text) ?? 0;
    if (!mounted) return;
    setState(() => _total = q * widget.crop.costPerKg);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24.w, 12.h, 24.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10))),
            SizedBox(height: 24.h),
            Text('Place Your Order',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 20.h),
            TextField(
              controller: widget.qtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantity (kg)',
                filled: true,
                fillColor: const Color(0xFFF1F4F6),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: widget.noteCtrl,
              decoration: InputDecoration(
                labelText: 'Note for farmer',
                filled: true,
                fillColor: const Color(0xFFF1F4F6),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimated Total',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text('₹${_total.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary)),
              ],
            ),
            SizedBox(height: 24.h),
            FLButton(
              label: 'Confirm Purchase',
              onPressed: () async {
                FocusScope.of(context).unfocus();
                if (mounted) setState(() => _localIsLoading = true);
                await widget.onPlace();
                if (mounted) setState(() => _localIsLoading = false);
              },
              isLoading: _localIsLoading || widget.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
