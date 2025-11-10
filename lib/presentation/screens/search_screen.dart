import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dev_connect/providers/auth_provider.dart';
import 'package:dev_connect/providers/theme_provider.dart';
import 'package:dev_connect/data/models/project_model.dart';
import 'package:dev_connect/components/project_card.dart';
import 'package:dev_connect/themes/app_theme.dart';
import 'package:dev_connect/constants/image_constants.dart';
import 'package:dev_connect/providers/projects_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _selectedFilter = 'Proyectos';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          'Buscar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
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
      body: Column(
        children: [
          _buildSearchBar(isDarkMode),
          _buildFilterChips(isDarkMode),
          Expanded(child: _buildSearchResults(currentUserId, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase().trim();
          });
        },
        decoration: InputDecoration(
          hintText: _selectedFilter == 'Proyectos'
              ? 'Buscar proyectos por nombre o tags...'
              : 'Buscar usuarios por nombre...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: isDarkMode
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFEFF2F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      child: Row(
        children: [
          _buildFilterChip('Proyectos', isDarkMode),
          const SizedBox(width: 8),
          _buildFilterChip('Usuarios', isDarkMode),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDarkMode) {
    final isSelected = _selectedFilter == label;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
          _searchQuery = '';
          _searchController.clear();
        });
      },
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSearchResults(String currentUserId, bool isDarkMode) {
    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: isDarkMode
                  ? AppTheme.darkText.withValues(alpha: 0.3)
                  : AppTheme.lightText.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Busca ${_selectedFilter.toLowerCase()}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isDarkMode
                    ? AppTheme.darkText.withValues(alpha: 0.5)
                    : AppTheme.lightText.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedFilter == 'Proyectos') {
      return _buildProjectsResults(currentUserId, isDarkMode);
    } else {
      return _buildUsersResults(currentUserId, isDarkMode);
    }
  }

  Widget _buildProjectsResults(String currentUserId, bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('projects')
          .where('status', isEqualTo: 'public')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final projects = snapshot.data?.docs ?? [];

        final filteredProjects = projects.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final tags = List<String>.from(data['tags'] ?? []);
          final authorName = (data['authorName'] ?? '')
              .toString()
              .toLowerCase();

          return title.contains(_searchQuery) ||
              tags.any((tag) => tag.toLowerCase().contains(_searchQuery)) ||
              authorName.contains(_searchQuery);
        }).toList();

        if (filteredProjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: isDarkMode
                      ? AppTheme.darkText.withValues(alpha: 0.3)
                      : AppTheme.lightText.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No se encontraron proyectos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredProjects.length,
          itemBuilder: (context, index) {
            final projectDoc = filteredProjects[index];
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

                await _firestore.collection('projects').doc(project.id).update({
                  'likes': updatedLikes,
                });
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
        );
      },
    );
  }

  Widget _buildUsersResults(String currentUserId, bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data?.docs ?? [];

        final filteredUsers = users.where((doc) {
          if (doc.id == currentUserId) return false;

          final data = doc.data() as Map<String, dynamic>;
          final displayName = (data['displayName'] ?? '')
              .toString()
              .toLowerCase();
          final bio = (data['bio'] ?? '').toString().toLowerCase();

          return displayName.contains(_searchQuery) ||
              bio.contains(_searchQuery);
        }).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search,
                  size: 80,
                  color: isDarkMode
                      ? AppTheme.darkText.withValues(alpha: 0.3)
                      : AppTheme.lightText.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No se encontraron usuarios',
                  style: Theme.of(context).textTheme.titleLarge,
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

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: userAvatar.isNotEmpty
                      ? CachedNetworkImageProvider(userAvatar)
                      : CachedNetworkImageProvider(
                          ImageConstants.getDefaultAvatar(userName),
                        ),
                ),
                title: Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  userBio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/profile_view',
                      arguments: userDoc.id,
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
