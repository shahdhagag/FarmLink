import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:farmlink/core/theme/app_theme.dart';

import '../../providers/app_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_card.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    final chatsAsync = ref.watch(userChatsProvider(user.uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Messages', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20.sp)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: chatsAsync.when(
        loading: () => ListView.separated(
          padding: EdgeInsets.all(20.w),
          itemCount: 4,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (_, __) => const ShimmerCard(height: 80),
        ),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load chats',
          subtitle: e.toString(),
        ),
        data: (rooms) {
          if (rooms.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No conversations yet',
              subtitle:
              'Start chatting with a farmer from any crop listing.',
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 120.h),
            physics: const BouncingScrollPhysics(),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (_, i) {
              final room = rooms[i];
              final otherUid = room.participantIds
                  .firstWhere((id) => id != user.uid, orElse: () => '');
              final otherName =
                  room.participantNames[otherUid] ?? 'Unknown';
              final unread = room.unreadCount[user.uid] ?? 0;

              return GestureDetector(
                onTap: () => context.push('/chat/${room.id}', extra: {
                  'otherUid': otherUid,
                  'otherName': otherName,
                  'cropName': room.cropName,
                }),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: unread > 0 ? AppColors.primary.withOpacity(0.03) : AppColors.surface,
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(
                        color: unread > 0
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.border.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 14.r,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(children: [
                    // Avatar
                    CircleAvatar(
                      radius: 28.r,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        otherName.isNotEmpty
                            ? otherName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),

                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(
                                otherName,
                                style: TextStyle(
                                  fontWeight: unread > 0
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 15.sp,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeago.format(room.lastMessageAt),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: unread > 0
                                    ? AppColors.primary
                                    : AppColors.textTertiary,
                                fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ]),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              room.cropName,
                              style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            room.lastMessage.isEmpty
                                ? 'Start the conversation'
                                : room.lastMessage,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: unread > 0
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: unread > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    if (unread > 0) ...[
                      SizedBox(width: 10.w),
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}