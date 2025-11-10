import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dev_connect/presentation/screens/home_screen.dart';
import 'package:dev_connect/presentation/screens/search_screen.dart';
import 'package:dev_connect/presentation/screens/profile_view_screen.dart';
import 'package:dev_connect/presentation/screens/chats_screen.dart';
import 'package:dev_connect/presentation/screens/notifications_screen.dart';
import 'package:dev_connect/providers/auth_provider.dart';
import 'package:dev_connect/services/notification_service.dart';
import 'package:dev_connect/themes/app_theme.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  final NotificationService _notificationService = NotificationService();

  static final List<Widget> _mainScreenOptions = <Widget>[
    const HomeScreen(),
    const SearchScreen(),
    const Center(child: Text('Pantalla de Crear')),
    const ChatsScreen(),
    const NotificationsScreen(),
    const ProfileViewScreen(),
  ];

  final PageController _pageController = PageController(initialPage: 0);

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, '/create_project');
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.uid ?? '';

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _mainScreenOptions,
      ),
      bottomNavigationBar: _buildModernBottomBar(currentUserId),
    );
  }

  Widget _buildModernBottomBar(String currentUserId) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, 'Inicio', 0, currentUserId),
          _buildNavItem(Icons.search_rounded, 'Buscar', 1, currentUserId),
          _buildNavItem(
            Icons.add_circle_outline_rounded,
            'Crear',
            2,
            currentUserId,
          ),
          _buildNavItem(Icons.chat_bubble_rounded, 'Chats', 3, currentUserId),
          _buildNavItem(
            Icons.notifications_rounded,
            'Alertas',
            4,
            currentUserId,
          ),
          _buildNavItem(Icons.person_rounded, 'Perfil', 5, currentUserId),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    String currentUserId,
  ) {
    final isSelected = _selectedIndex == index;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final iconColor = isSelected
        ? AppTheme.primaryColor
        : (isDarkMode ? Colors.grey[500] : Colors.grey[600]);

    final textColor = isSelected
        ? AppTheme.primaryColor
        : (isDarkMode ? Colors.grey[500] : Colors.grey[600]);

    Widget iconWidget = Icon(icon, color: iconColor, size: 26);

    if (index == 3 && currentUserId.isNotEmpty) {
      return StreamBuilder<int>(
        stream: _notificationService.getUnreadChatsCount(currentUserId),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return _buildNavItemContent(
            count > 0 ? _buildBadgeIcon(iconWidget, count) : iconWidget,
            label,
            index,
            iconColor,
            textColor,
          );
        },
      );
    } else if (index == 4 && currentUserId.isNotEmpty) {
      return StreamBuilder<int>(
        stream: _notificationService.getUnreadNotificationsCount(currentUserId),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return _buildNavItemContent(
            count > 0 ? _buildBadgeIcon(iconWidget, count) : iconWidget,
            label,
            index,
            iconColor,
            textColor,
          );
        },
      );
    }

    return _buildNavItemContent(iconWidget, label, index, iconColor, textColor);
  }

  Widget _buildNavItemContent(
    Widget icon,
    String label,
    int index,
    Color? iconColor,
    Color? textColor,
  ) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => _onItemTapped(index),
      splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      highlightColor: AppTheme.primaryColor.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(Widget icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -8,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
