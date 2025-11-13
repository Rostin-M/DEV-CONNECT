import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dev_connect/providers/auth_provider.dart';
import 'package:dev_connect/providers/theme_provider.dart';
import 'package:dev_connect/services/chat_service.dart';
import 'package:dev_connect/data/models/chat_model.dart';
import 'package:dev_connect/themes/app_theme.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentUserId = authProvider.user?.uid;
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Error: Usuario no autenticado')),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBg : AppTheme.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDarkMode, themeProvider),
            Expanded(
              child: StreamBuilder<List<ChatModel>>(
                stream: _chatService.getUserChats(currentUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final chats = snapshot.data ?? [];

                  if (chats.isEmpty) {
                    return _buildEmptyState(isDarkMode);
                  }

                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return _buildChatItem(
                        context,
                        chat,
                        currentUserId,
                        isDarkMode,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDarkMode,
    ThemeProvider themeProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mensajes',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () {
                  themeProvider.toggleTheme(!isDarkMode);
                },
              ),
              IconButton(
                icon: const Icon(Icons.search, color: AppTheme.primaryColor),
                onPressed: () {
                  _showUserSearchDialog(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No hay conversaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comienza una conversación con otros usuarios',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showUserSearchDialog(context);
            },
            icon: const Icon(Icons.person_search),
            label: const Text('Buscar usuarios'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserSearchDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.uid;

    if (currentUserId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserSearchDialog(currentUserId: currentUserId),
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    ChatModel chat,
    String currentUserId,
    bool isDarkMode,
  ) {
    final otherUserId = chat.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return const SizedBox.shrink();

    final otherUserData =
        chat.participantsData[otherUserId] as Map<String, dynamic>?;
    final otherUserName = otherUserData?['displayName'] ?? 'Usuario';
    final otherUserAvatar = otherUserData?['photoURL'] ?? '';

    final avatarUrl = otherUserAvatar.isNotEmpty
        ? otherUserAvatar
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(otherUserName)}&background=random&size=200&bold=true';

    final unreadCount = chat.unreadCount[currentUserId] ?? 0;
    final isUnread = unreadCount > 0;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/chat_detail',
          arguments: {
            'chatId': chat.id,
            'otherUserId': otherUserId,
            'otherUserName': otherUserName,
            'otherUserAvatar': avatarUrl,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUnread
              ? (isDarkMode
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : AppTheme.primaryColor.withValues(alpha: 0.05))
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(avatarUrl),
                  radius: 28,
                  backgroundColor: Colors.grey[300],
                ),
                if (isUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUserName,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.lastMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUnread
                          ? (isDarkMode ? Colors.white70 : Colors.black87)
                          : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      fontWeight: isUnread
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(chat.lastMessageTime.toDate()),
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnread
                        ? AppTheme.primaryColor
                        : (isDarkMode ? Colors.grey[500] : Colors.grey[500]),
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class UserSearchDialog extends StatefulWidget {
  final String currentUserId;

  const UserSearchDialog({super.key, required this.currentUserId});

  @override
  State<UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<UserSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      setState(() {
        _searchResults = usersSnapshot.docs
            .where((doc) => doc.id != widget.currentUserId)
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al buscar: $e')));
      }
    }
  }

  Future<void> _startChat(String otherUserId, String otherUserName) async {
    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final currentUserDoc = await _firestore
          .collection('users')
          .doc(widget.currentUserId)
          .get();
      final currentUserData = currentUserDoc.data() ?? {};

      final otherUserDoc = await _firestore
          .collection('users')
          .doc(otherUserId)
          .get();
      final otherUserData = otherUserDoc.data() ?? {};

      final chatId = await _chatService.getOrCreateChat(
        widget.currentUserId,
        otherUserId,
        {
          'displayName': currentUserData['displayName'] ?? 'Usuario',
          'photoURL': currentUserData['photoURL'] ?? '',
        },
        {
          'displayName': otherUserData['displayName'] ?? otherUserName,
          'photoURL': otherUserData['photoURL'] ?? '',
        },
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.pushNamed(
          context,
          '/chat_detail',
          arguments: {
            'chatId': chatId,
            'otherUserId': otherUserId,
            'otherUserName': otherUserData['displayName'] ?? otherUserName,
            'otherUserAvatar': otherUserData['photoURL'] ?? '',
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Buscar usuarios',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                ),
                onChanged: (value) {
                  if (value.length >= 2) {
                    _searchUsers(value);
                  } else {
                    setState(() {
                      _searchResults = [];
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Escribe para buscar usuarios'
                                  : 'No se encontraron usuarios',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final userName = user['displayName'] ?? 'Usuario';
                          final userAvatar = user['photoURL'] ?? '';
                          final userBio = user['bio'] ?? 'Sin biografía';

                          final avatarUrl = userAvatar.isNotEmpty
                              ? userAvatar
                              : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&background=random&size=200&bold=true';

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundImage: CachedNetworkImageProvider(
                                avatarUrl,
                              ),
                              backgroundColor: Colors.grey[300],
                            ),
                            title: Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              userBio,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.chat_bubble),
                              color: AppTheme.primaryColor,
                              onPressed: () => _startChat(user['id'], userName),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
