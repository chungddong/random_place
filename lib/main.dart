import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_theme.dart';
import 'config/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/scrap_provider.dart';
import 'providers/folder_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp();

  // dotenv 로드
  await dotenv.load(fileName: 'assets/env/.env');

  // 카카오맵 초기화
  AuthRepository.initialize(
    appKey: dotenv.env['APP_KEY'] ?? '',
    baseUrl: dotenv.env['BASE_URL'] ?? '',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ScrapProvider()),
        ChangeNotifierProvider(create: (_) => FolderProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        // 로그인 상태가 변경되면 FolderProvider 구독 시작/중지
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final folderProvider = Provider.of<FolderProvider>(context, listen: false);
          if (authProvider.isLoggedIn && authProvider.user != null) {
            folderProvider.subscribeToUserFolders(authProvider.user!.uid);
          } else {
            folderProvider.unsubscribe();
          }
        });

        return MaterialApp(
          title: 'Random Place',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: authProvider.isLoggedIn ? const MainScreen() : const LoginScreen(),
        );
      },
    );
  }
}


