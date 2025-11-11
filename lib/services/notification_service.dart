import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getUnreadChatsCount(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          int unreadCount = 0;
          for (var doc in snapshot.docs) {
            final chatData = doc.data();
            final unreadMap = chatData['unreadCount'] as Map<String, dynamic>?;
            unreadCount += (unreadMap?[userId] as int?) ?? 0;
          }
          return unreadCount;
        });
  }

  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationData = {
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        if (data != null) ...data,
      };

      await _firestore.collection('notifications').add(notificationData);
    } catch (e) {
      debugPrint(' Error al crear notificación: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  Future<void> markAllAsRead(String userId) async {
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> notifyNewMessage({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String chatId,
    required String messagePreview,
  }) async {
    await createNotification(
      userId: recipientId,
      type: 'message',
      title: 'Nuevo mensaje',
      message: '$senderName: $messagePreview',
      data: {
        'chatId': chatId,
        'otherUserId': senderId,
        'otherUserName': senderName,
        'otherUserAvatar': senderAvatar,
      },
    );
  }

  Future<void> notifyNewComment({
    required String recipientId,
    required String commenterName,
    required String projectId,
    required String projectTitle,
  }) async {
    await createNotification(
      userId: recipientId,
      type: 'comment',
      title: 'Nuevo comentario',
      message: '$commenterName comentó en tu proyecto "$projectTitle"',
      data: {'type': 'comment', 'projectId': projectId},
    );
  }

  Future<void> notifyNewLike({
    required String recipientId,
    required String likerName,
    required String projectId,
    required String projectTitle,
  }) async {
    await createNotification(
      userId: recipientId,
      type: 'like',
      title: 'Nuevo like',
      message: 'A $likerName le gustó tu proyecto "$projectTitle"',
      data: {'type': 'like', 'projectId': projectId},
    );
  }

  Future<void> notifyNewProject({
    required String authorId,
    required String authorName,
    required String projectId,
    required String projectTitle,
  }) async {
    final usersSnapshot = await _firestore.collection('users').get();

    for (var userDoc in usersSnapshot.docs) {
      if (userDoc.id != authorId) {
        await createNotification(
          userId: userDoc.id,
          type: 'new_project',
          title: 'Nuevo proyecto',
          message: '$authorName publicó "$projectTitle"',
          data: {'projectId': projectId, 'type': 'new_project'},
        );
      }
    }
  }
}
