import 'package:flutter/material.dart';
import 'package:dev_connect/presentation/screens/home_screen.dart';
import 'package:dev_connect/presentation/screens/profile_view_screen.dart';
import 'package:dev_connect/themes/app_theme.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  static final List<Widget> _mainScreenOptions = <Widget>[
    const HomeScreen(),
    const Center(child: Text('Pantalla de Búsqueda')),
    const Center(
      child: Text('Pantalla de Notificaciones'),
    ),
    const ProfileViewScreen(),
  ];

  final PageController _pageController = PageController(initialPage: 0);

  void _onItemTapped(int index) {
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
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _mainScreenOptions,
      ),
      floatingActionButton: _buildCustomCreateButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildCustomCreateButton() {
    return Container(
      height: 56.0,
      width: 56.0,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/create_project');
          },
          customBorder: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      elevation: 8.0,
      height: 65.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBottomNavItem(Icons.home_outlined, Icons.home, 0),
                const SizedBox(width: 16),
                _buildBottomNavItem(Icons.search_outlined, Icons.search, 1),
              ],
            ),

            const SizedBox(width: 56),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBottomNavItem(
                  Icons.notifications_outlined,
                  Icons.notifications,
                  2,
                ),
                const SizedBox(width: 16),
                _buildBottomNavItem(Icons.person_outline, Icons.person, 3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData outlineIcon,
    IconData filledIcon,
    int index,
  ) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppTheme.primaryColor : AppTheme.neutralColor;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            isSelected ? filledIcon : outlineIcon,
            key: ValueKey<bool>(isSelected),
            color: color,
            size: 28,
          ),
        ),
      ),
    );
  }
}
