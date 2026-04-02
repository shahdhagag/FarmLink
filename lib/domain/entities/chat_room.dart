import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom extends Equatable {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String cropId;
  final String cropName;
  final Map<String, int> unreadCount;

  const ChatRoom({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.cropId,
    required this.cropName,
    required this.unreadCount,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoom(
      id: id,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageAt:
          (map['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cropId: map['cropId'] ?? '',
      cropName: map['cropName'] ?? '',
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'participantIds': participantIds,
        'participantNames': participantNames,
        'lastMessage': lastMessage,
        'lastMessageAt': Timestamp.fromDate(lastMessageAt),
        'cropId': cropId,
        'cropName': cropName,
        'unreadCount': unreadCount,
      };

  @override
  List<Object?> get props => [id, participantIds, cropId];
}

