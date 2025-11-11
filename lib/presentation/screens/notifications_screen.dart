import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dev_connect/providers/auth_provider.dart';
import 'package:dev_connect/providers/theme_provider.dart';
import 'package:dev_connect/services/notification_service.dart';
import 'package:dev_connect/themes/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.uid ?? '';

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await _notificationService.markAllAsRead(currentUserId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Todas las notificaciones marcadas como leídas',
                    ),
                  ),
                );
              }
            },
            tooltip: 'Marcar todas como leídas',
          ),
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: AppTheme.primaryColor,
            ),
            onPressed: () {
              themeProvider.toggleTheme(!isDarkMode);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUserId)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: isDarkMode
                        ? AppTheme.darkText.withValues(alpha: 0.3)
                        : AppTheme.lightText.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;
              final isRead = data['read'] ?? false;
              final type = data['type'] ?? 'info';
              final title = data['title'] ?? '';
              final message = data['message'] ?? '';
              final createdAt = data['createdAt'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: isRead
                    ? null
                    : AppTheme.primaryColor.withValues(alpha: 0.05),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getNotificationColor(type),
                    child: Icon(
                      _getNotificationIcon(type),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(message),
                      if (createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          timeago.format(createdAt.toDate(), locale: 'es'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: isRead
                      ? null
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                  onTap: () async {
                    if (!isRead) {
                      await _notificationService.markAsRead(notification.id);
                    }

                    if (data.containsKey('chatId') ||
                        data.containsKey('projectId') ||
                        data.containsKey('userId')) {
                      _handleNotificationTap(context, type, data);
                    } else {
                      _showErrorSnackBar(
                        context,
                        'No hay información suficiente para abrir esta notificación',
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'follow':
        return Colors.green;
      case 'message':
        return AppTheme.primaryColor;
      case 'new_project':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'follow':
        return Icons.person_add;
      case 'message':
        return Icons.message;
      case 'new_project':
        return Icons.add_box;
      default:
        return Icons.notifications;
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    String type,
    Map<String, dynamic> data,
  ) {
    switch (type) {
      case 'like':
      case 'comment':
      case 'new_project':
        final projectId = data['projectId'];
        if (projectId != null && projectId is String) {
          Navigator.pushNamed(context, '/project_detail', arguments: projectId);
        } else {
          _showErrorSnackBar(context, 'No se pudo abrir el proyecto');
        }
        break;
      case 'follow':
        final userId = data['userId'];
        if (userId != null && userId is String) {
          Navigator.pushNamed(context, '/profile_view', arguments: userId);
        } else {
          _showErrorSnackBar(context, 'No se pudo abrir el perfil');
        }
        break;
      case 'message':
        final chatId = data['chatId'];
        final otherUserId = data['otherUserId'];
        final otherUserName = data['otherUserName'];
        final otherUserAvatar = data['otherUserAvatar'];

        debugPrint('Datos de notificación de mensaje:');
        debugPrint('chatId: $chatId (${chatId.runtimeType})');
        debugPrint('otherUserId: $otherUserId (${otherUserId.runtimeType})');
        debugPrint(
          'otherUserName: $otherUserName (${otherUserName.runtimeType})',
        );
        debugPrint(
          'otherUserAvatar: $otherUserAvatar (${otherUserAvatar.runtimeType})',
        );

        if (chatId != null && otherUserId != null) {
          Navigator.pushNamed(
            context,
            '/chat_detail',
            arguments: {
              'chatId': chatId.toString(),
              'otherUserId': otherUserId.toString(),
              'otherUserName': (otherUserName ?? 'Usuario').toString(),
              'otherUserAvatar': (otherUserAvatar ?? '').toString(),
            },
          );
        } else {
          _showErrorSnackBar(
            context,
            'No se pudo abrir el chat. Faltan datos: chatId=${chatId != null}, otherUserId=${otherUserId != null}',
          );
        }
        break;
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
