import 'package:flutter/material.dart';
import 'package:farmlink/core/theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Assuming you use ScreenUtil for consistency

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const InfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Keeps icon at the top if text wraps
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: iconColor ?? AppColors.primary,
          ),
          SizedBox(width: 12.w),
          // ── THE FIX: Wrap in Expanded ──────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                  // No need for softWrap here usually, but good for safety
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  softWrap: true, // Now this will work!
                  maxLines: 3,    // Increased to 3 for very long addresses
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}