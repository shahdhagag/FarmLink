import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:farmlink/core/theme/app_theme.dart';

import '../../providers/app_provider.dart';
import '../../../domain/entities/message.dart';
import '../../widgets/empty_state.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUid;
  final String otherName;
  final String cropName;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUid,
    required this.otherName,
    required this.cropName,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        ref.read(firestoreServiceProvider).markMessagesRead(widget.chatId, user.uid);
      }
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      final message = ChatMessage(
        id: '',
        senderId: user.uid,
        text: text,
        sentAt: DateTime.now(),
        senderName: user.name,
      );

      await ref.read(firestoreServiceProvider).sendMessage(
        chatId: widget.chatId,
        message: message,
        otherUid: widget.otherUid,
      );

      _messageCtrl.clear();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.otherName, style: TextStyle(fontSize: 18.sp, color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(widget.cropName, style: TextStyle(fontSize: 11.sp, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(height: 1.h, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Error', subtitle: e.toString()),
              data: (messages) {
                if (messages.isEmpty) {
                  return const EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No messages yet',
                    subtitle: 'Send a message to start the conversation.',
                  );
                }

                if (user != null) {
                  ref.read(firestoreServiceProvider).markMessagesRead(widget.chatId, user.uid);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[messages.length - 1 - index];
                    final isMe = msg.senderId == user?.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12.h, top: 4.h),
                        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.r),
                            topRight: Radius.circular(20.r),
                            bottomLeft: Radius.circular(isMe ? 20.r : 4.r),
                            bottomRight: Radius.circular(isMe ? 4.r : 20.r),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isMe
                                  ? AppColors.primary.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.06),
                              blurRadius: 10.r,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              msg.text,
                              style: TextStyle(
                                color: isMe ? Colors.white : AppColors.textPrimary,
                                fontSize: 15.sp,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              DateFormat('hh:mm a').format(msg.sentAt),
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: isMe ? Colors.white60 : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.08, end: 0),
                    );
                  },
                );
              },
            ),
          ),

          // Chat input
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, MediaQuery.of(context).padding.bottom + 12.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border, width: 1.h)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10.r,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8.r,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _messageCtrl,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(fontSize: 14.sp, color: AppColors.textTertiary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28.r),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12.r,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isSending
                        ? SizedBox(width: 22.sp, height: 22.sp, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Icon(Icons.send_rounded, color: Colors.white, size: 22.sp),
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
