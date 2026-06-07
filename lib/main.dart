import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/calendar_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_tab_screen.dart';
import 'screens/couple/connect_couple_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CoupleApp());
}

class CoupleApp extends StatelessWidget {
  const CoupleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
      ],
      child: MaterialApp(
        title: 'Couple Calendar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final authStatus = context.select<app_auth.AuthProvider,
        app_auth.AuthStatus>((p) => p.status);
    final isConnected =
        context.select<app_auth.AuthProvider, bool>((p) => p.isConnected);

    switch (authStatus) {
      case app_auth.AuthStatus.initial:
      case app_auth.AuthStatus.loading:
        return const _SplashScreen();

      case app_auth.AuthStatus.authenticated:
        if (!isConnected) {
          return const _ConnectWrapper();
        }
        return const MainTabScreen();

      case app_auth.AuthStatus.unauthenticated:
      case app_auth.AuthStatus.error:
        return const LoginScreen();
    }
  }
}

/// Shown while Firebase is initialising
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_rounded,
              size: 72,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Couple Calendar',
              style: AppTheme.theme.textTheme.displayMedium?.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

/// Navigates authenticated-but-not-connected users to the connect screen
/// while still showing the main tab (so back navigation works after connecting)
class _ConnectWrapper extends StatelessWidget {
  const _ConnectWrapper();

  @override
  Widget build(BuildContext context) {
    return const ConnectCoupleScreen();
  }
}
