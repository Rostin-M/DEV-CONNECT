import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';

import 'package:dev_connect/providers/auth_provider.dart';
import 'package:dev_connect/providers/theme_provider.dart';
import 'package:dev_connect/providers/projects_provider.dart';

import 'package:dev_connect/themes/app_theme.dart';

import 'package:dev_connect/presentation/screens/splash_screen.dart';
import 'package:dev_connect/presentation/screens/login_screen.dart';
import 'package:dev_connect/presentation/screens/register_screen.dart';
import 'package:dev_connect/presentation/screens/forgot_password_screen.dart';
import 'package:dev_connect/presentation/screens/main_scaffold.dart';
import 'package:dev_connect/presentation/screens/project_create_screen.dart';
import 'package:dev_connect/presentation/screens/profile_view_screen.dart';
import 'package:dev_connect/presentation/screens/profile_edit_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => ProjectsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'DevConnect',
          debugShowCheckedModeBanner: false,

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/forgot': (context) => const ForgotPasswordScreen(),
            '/home': (context) => const MainScaffold(),
            '/create_project': (context) => const ProjectCreateScreen(),

            '/profile_view': (context) => const ProfileViewScreen(),
            '/profile_edit': (context) => const ProfileEditScreen(),

            '/project_detail': (context) =>
                const PlaceholderScreen(title: 'Detalle de Proyecto'),
            '/project_comments': (context) =>
                const PlaceholderScreen(title: 'Comentarios'),
          },
        );
      },
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'Pantalla: $title',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
