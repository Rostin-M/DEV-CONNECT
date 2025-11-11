import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dev_connect/data/models/chat_model.dart';
import 'package:dev_connect/data/models/message_model.dart';
import 'package:dev_connect/services/notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  Future<String> getOrCreateChat(
    String currentUserId,
    String otherUserId,
    Map<String, dynamic> currentUserData,
    Map<String, dynamic> otherUserData,
  ) async {
    final existingChat = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in existingChat.docs) {
      final participants = List<String>.from(doc.data()['participants']);
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    final chatData = {
      'participants': [currentUserId, otherUserId],
      'participantsData': {
        currentUserId: currentUserData,
        otherUserId: otherUserData,
      },
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSender': '',
      'unreadCount': {currentUserId: 0, otherUserId: 0},
      'createdAt': FieldValue.serverTimestamp(),
    };

    final chatRef = await _firestore.collection('chats').add(chatData);
    return chatRef.id;
  }

  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> sendMessage(
    String chatId,
    String senderId,
    String senderName,
    String senderAvatar,
    String text,
    String receiverId,
  ) async {
    final messageData = {
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSender': senderId,
      'unreadCount.$receiverId': FieldValue.increment(1),
    });

    await _notificationService.notifyNewMessage(
      recipientId: receiverId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      chatId: chatId,
      messagePreview: text.length > 50 ? '${text.substring(0, 50)}...' : text,
    );
  }

  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.$userId': 0,
    });

    final messagesSnapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messagesSnapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
            total += (unreadCount?[userId] as int?) ?? 0;
          }
          return total;
        });
  }
}
