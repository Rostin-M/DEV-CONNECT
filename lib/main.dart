import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
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
import 'package:dev_connect/presentation/screens/project_detail_screen.dart';
import 'package:dev_connect/presentation/screens/chat_detail_screen.dart';
import 'package:dev_connect/presentation/screens/search_screen.dart';
import 'package:dev_connect/presentation/screens/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
  );

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
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(builder: (_) => const SplashScreen());
              case '/login':
                return MaterialPageRoute(builder: (_) => const LoginScreen());
              case '/register':
                return MaterialPageRoute(
                  builder: (_) => const RegisterScreen(),
                );
              case '/forgot':
                return MaterialPageRoute(
                  builder: (_) => const ForgotPasswordScreen(),
                );
              case '/home':
                return MaterialPageRoute(builder: (_) => const MainScaffold());
              case '/create_project':
                return MaterialPageRoute(
                  builder: (_) => const ProjectCreateScreen(),
                );
              case '/profile_view':
                return MaterialPageRoute(
                  builder: (_) => const ProfileViewScreen(),
                );
              case '/profile_edit':
                return MaterialPageRoute(
                  builder: (_) => const ProfileEditScreen(),
                );
              case '/project_detail':
                final projectId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (_) => ProjectDetailScreen(projectId: projectId),
                );
              case '/chat_detail':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    chatId: args['chatId'],
                    otherUserId: args['otherUserId'],
                    otherUserName: args['otherUserName'],
                    otherUserAvatar: args['otherUserAvatar'],
                  ),
                );
              case '/search':
                return MaterialPageRoute(builder: (_) => const SearchScreen());
              case '/notifications':
                return MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                );
              case '/project_comments':
                final projectId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (_) => ProjectDetailScreen(projectId: projectId),
                );
              default:
                return MaterialPageRoute(builder: (_) => const SplashScreen());
            }
          },
        );
      },
    );
  }
}
