import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dev_connect/components/project_card_shimmer.dart';
import 'package:dev_connect/providers/auth_provider.dart';
import 'package:dev_connect/providers/projects_provider.dart';
import 'package:dev_connect/providers/theme_provider.dart';
import 'package:dev_connect/components/project_card.dart';
import 'package:dev_connect/themes/app_theme.dart';
import 'package:dev_connect/data/models/project_model.dart';
import 'package:dev_connect/services/chat_service.dart';
import 'package:dev_connect/constants/image_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();

  String _selectedTag = '';
  List<String> _popularTags = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadPopularTags();
  }

  Future<void> _loadPopularTags() async {
    try {
      final projectsSnapshot = await _firestore
          .collection('projects')
          .where('status', isEqualTo: 'public')
          .get();

      final Map<String, int> tagCount = {};

      for (var doc in projectsSnapshot.docs) {
        final data = doc.data();
        final tags = List<String>.from(data['tags'] ?? []);

        for (var tag in tags) {
          tagCount[tag] = (tagCount[tag] ?? 0) + 1;
        }
      }

      final sortedTags = tagCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        _popularTags = sortedTags.take(6).map((e) => e.key).toList();
      });
    } catch (e) {
      debugPrint('Error loading popular tags: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Provider.of<ProjectsProvider>(context, listen: false).fetchMoreProjects();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBg : AppTheme.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDarkMode),
            _buildTagFilters(isDarkMode),
            Expanded(
              child: _tabController == null
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController!,
                      children: [_buildFeedTab(), _buildDevelopersTab()],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Feed',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
              IconButton(
                icon: Icon(
                  isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () {
                  themeProvider.toggleTheme(!isDarkMode);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/search');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFEFF2F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppTheme.neutralColor),
                  const SizedBox(width: 12),
                  Text(
                    'Buscar proyectos, usuarios...',
                    style: TextStyle(
                      color: AppTheme.neutralColor.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagFilters(bool isDarkMode) {
    if (_popularTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTagChip('Todos', '', isDarkMode),
          const SizedBox(width: 8),
          ..._popularTags.map(
            (tag) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildTagChip(tag, tag, isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String label, String value, bool isDarkMode) {
    final isSelected = _selectedTag == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTag = selected ? value : '';
        });
      },
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? AppTheme.primaryColor
            : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
      ),
    );
  }

  Widget _buildFeedTab() {
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.uid;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (currentUserId == null) {
      return const Center(child: Text("Error: Usuario no autenticado."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('projects')
          .where('status', isEqualTo: 'public')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  "Error al cargar proyectos",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            itemCount: 3,
            itemBuilder: (context, index) => const ProjectCardShimmer(),
          );
        }

        var projects = snapshot.data?.docs ?? [];

        // Filtrar por tag si hay uno seleccionado
        if (_selectedTag.isNotEmpty) {
          projects = projects.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final tags = List<String>.from(data['tags'] ?? []);
            return tags.contains(_selectedTag);
          }).toList();
        }

        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.explore_off_outlined,
                  size: 80,
                  color: isDarkMode
                      ? AppTheme.darkText.withValues(alpha: 0.5)
                      : AppTheme.lightText.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  _selectedTag.isEmpty
                      ? "No hay proyectos"
                      : "No hay proyectos con #$_selectedTag",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedTag.isEmpty
                      ? "Sé el primero en publicar un proyecto"
                      : "Intenta con otro filtro",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutralColor,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadPopularTags();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            controller: _scrollController,
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final projectDoc = projects[index];
              final projectData = projectDoc.data() as Map<String, dynamic>;

              final project = ProjectModel(
                id: projectDoc.id,
                title: projectData['title'] ?? '',
                description: projectData['description'] ?? '',
                tags: List<String>.from(projectData['tags'] ?? []),
                githubLink: projectData['githubLink'] ?? '',
                screenshots: List<Map<String, dynamic>>.from(
                  (projectData['screenshots'] as List?)?.map((e) {
                        if (e is String) {
                          return {'url': e, 'caption': ''};
                        }
                        return e as Map<String, dynamic>;
                      }) ??
                      [],
                ),
                authorId: projectData['authorId'] ?? '',
                authorName: projectData['authorName'] ?? 'Anónimo',
                authorAvatar: projectData['authorAvatar'] ?? '',
                createdAt: projectData['createdAt'] ?? Timestamp.now(),
                updatedAt: projectData['updatedAt'] ?? Timestamp.now(),
                likes: List<String>.from(projectData['likes'] ?? []),
                commentsCount: projectData['commentsCount'] ?? 0,
                status: projectData['status'] ?? 'public',
              );

              return ProjectCard(
                project: project,
                currentUserId: currentUserId,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/project_detail',
                    arguments: project.id,
                  );
                },
                onLikeToggle: () async {
                  final liked = project.likes.contains(currentUserId);
                  final updatedLikes = List<String>.from(project.likes);

                  if (liked) {
                    updatedLikes.remove(currentUserId);
                  } else {
                    updatedLikes.add(currentUserId);
                  }

                  await _firestore
                      .collection('projects')
                      .doc(project.id)
                      .update({'likes': updatedLikes});
                },
                onShare: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Función 'Compartir' próximamente"),
                    ),
                  );
                },
                onComment: () {
                  Navigator.pushNamed(
                    context,
                    '/project_detail',
                    arguments: project.id,
                  );
                },
                onDelete: project.authorId == currentUserId
                    ? () async {
                        final projectsProvider = Provider.of<ProjectsProvider>(
                          context,
                          listen: false,
                        );

                        final success = await projectsProvider.deleteProject(
                          project.id,
                          currentUserId,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Proyecto eliminado correctamente'
                                    : 'Error al eliminar el proyecto',
                              ),
                              backgroundColor: success
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          );
                        }
                      }
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDevelopersTab() {
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.uid;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (currentUserId == null) {
      return const Center(child: Text("Error: Usuario no autenticado."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];
        final filteredUsers = users
            .where((doc) => doc.id != currentUserId)
            .toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: isDarkMode
                      ? AppTheme.darkText.withValues(alpha: 0.5)
                      : AppTheme.lightText.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  "No hay desarrolladores",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final userDoc = filteredUsers[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            final userName = userData['displayName'] ?? 'Usuario';
            final userAvatar = userData['photoURL'] ?? '';
            final userBio = userData['bio'] ?? 'Desarrollador';
            final userSkills = List<String>.from(userData['skills'] ?? []);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: userAvatar.isNotEmpty
                              ? CachedNetworkImageProvider(userAvatar)
                              : CachedNetworkImageProvider(
                                  ImageConstants.getDefaultAvatar(userName),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userBio,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.neutralColor),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline),
                          color: AppTheme.primaryColor,
                          onPressed: () =>
                              _startChatWithUser(userDoc.id, userName),
                        ),
                      ],
                    ),
                    if (userSkills.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: userSkills.take(5).map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor.withValues(alpha: 0.2),
                                  AppTheme.secondaryColor.withValues(
                                    alpha: 0.2,
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              skill,
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startChatWithUser(
    String otherUserId,
    String otherUserName,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.uid;

    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Usuario no autenticado")),
        );
      }
      return;
    }

    try {
      // Obtener datos del usuario actual
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      final currentUserData = currentUserDoc.data() ?? {};

      // Obtener datos del otro usuario
      final otherUserDoc = await _firestore
          .collection('users')
          .doc(otherUserId)
          .get();

      final otherUserData = otherUserDoc.data() ?? {};

      final chatId = await _chatService.getOrCreateChat(
        currentUserId,
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
        Navigator.pushNamed(
          context,
          '/chat_detail',
          arguments: {
            'chatId': chatId,
            'otherUserName': otherUserData['displayName'] ?? otherUserName,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al iniciar chat: $e")));
      }
    }
  }
}
