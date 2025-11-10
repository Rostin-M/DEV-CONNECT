import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dev_connect/components/project_card_shimmer.dart';
import 'package:dev_connect/providers/auth_provider.dart';
import 'package:dev_connect/providers/projects_provider.dart';
import 'package:dev_connect/providers/theme_provider.dart';
import 'package:dev_connect/components/project_card.dart';
import 'package:dev_connect/themes/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProjectsProvider>(context, listen: false);
      if (provider.projects.isEmpty) {
        provider.fetchInitialProjects();
      }
    });

    _scrollController.addListener(_onScroll);
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

            _buildTabBar(isDarkMode),

            Expanded(
              child: _tabController == null
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController!,
                      children: [_buildFeedTab(), _buildChatsTab()],
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
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () {
                  themeProvider.toggleTheme(!isDarkMode);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
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
                  'Buscar',
                  style: TextStyle(
                    color: AppTheme.neutralColor.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTab(Icons.favorite_border, 'Favoritos', isDarkMode),
            _buildTab(Icons.history, 'Historial', isDarkMode),
            _buildTab(Icons.people_outline, 'Seguidos', isDarkMode),
            _buildTab(Icons.list_alt, 'Todos', isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(IconData icon, String label, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDarkMode
                ? AppTheme.neutralColor.withValues(alpha: 0.3)
                : AppTheme.neutralColor.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isDarkMode ? AppTheme.darkText : AppTheme.lightText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isDarkMode ? AppTheme.darkText : AppTheme.lightText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTab() {
    final projectsProvider = context.watch<ProjectsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.uid;

    if (currentUserId == null) {
      return const Center(child: Text("Error: Usuario no autenticado."));
    }

    if (projectsProvider.isLoading && projectsProvider.projects.isEmpty) {
      return ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) => const ProjectCardShimmer(),
      );
    }

    if (projectsProvider.error != null && projectsProvider.projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Error: ${projectsProvider.error}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => projectsProvider.fetchInitialProjects(),
              child: const Text("Reintentar"),
            ),
          ],
        ),
      );
    }

    if (projectsProvider.projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off_outlined,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 20),
            Text(
              "No hay proyectos",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Text("Sé el primero en publicar un proyecto."),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: projectsProvider.refreshProjects,
      child: ListView.builder(
        controller: _scrollController,
        itemCount:
            projectsProvider.projects.length +
            (projectsProvider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == projectsProvider.projects.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final project = projectsProvider.projects[index];
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
            onLikeToggle: () {
              projectsProvider.toggleLike(project.id, currentUserId);
            },
            onShare: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Función 'Compartir' no implementada"),
                ),
              );
            },
            onComment: () {
              Navigator.pushNamed(
                context,
                '/project_comments',
                arguments: project.id,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatsTab() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: Text('U${index + 1}'),
          ),
          title: Text('Usuario ${index + 1}'),
          subtitle: const Text('Último mensaje...'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Chat no implementado")),
            );
          },
        );
      },
    );
  }
}
