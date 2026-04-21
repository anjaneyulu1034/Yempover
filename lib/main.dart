import 'package:Yempover_app/services/notification1_service.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'utils/notification_provider.dart';
import 'screens/SplashScreen.dart';

// Global notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// 🔥 Background message handler
/// MUST be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 🔥 Required for background messages
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase background init skipped: $e');
    return;
  }
  debugPrint("📩 Background message received: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 STEP 1: Initialize Firebase FIRST
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase init failed, continuing without push features: $e');
  }

  // 🔥 STEP 2/3: Configure push features only when Firebase is ready
  if (firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService1().init();
  }

  // 🔥 STEP 4: Run app
  runApp(const MyApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService1.flushPendingNavigation();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        title: 'Yempover',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF1A73E8),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A73E8),
            primary: const Color(0xFF1A73E8),
            surface: Colors.white.withValues(alpha: 0.22),
            surfaceContainerHigh: Colors.white.withValues(alpha: 0.18),
          ),
          fontFamily: 'Roboto',
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.black,
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          listTileTheme: ListTileThemeData(
            tileColor: Colors.white.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            iconColor: const Color(0xFF1A73E8),
            textColor: const Color(0xFF132235),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white.withValues(alpha: 0.25),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.22),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.30),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.40),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF1A73E8),
                width: 1.2,
              ),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF163A63),
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.48)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10243D).withValues(alpha: 0.90),
            contentTextStyle: const TextStyle(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.white.withValues(alpha: 0.20),
            elevation: 0,
            selectedItemColor: const Color(0xFF1A73E8),
            unselectedItemColor: const Color(0xFF3F4F63),
            type: BottomNavigationBarType.fixed,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white.withValues(alpha: 0.20),
            indicatorColor: const Color(0xFF1A73E8).withValues(alpha: 0.22),
            elevation: 0,
          ),
        ),
        builder: (context, child) {
          return _AppGlassBackground(child: child ?? const SizedBox.shrink());
        },
        home: const SplashScreen(),
      ),
    );
  }
}

class _AppGlassBackground extends StatelessWidget {
  const _AppGlassBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE6F0FF), Color(0xFFDDF6F2), Color(0xFFF7ECFF)],
            ),
          ),
        ),
        Positioned(
          top: -80,
          left: -60,
          child: _glassOrb(
            size: 220,
            color: const Color(0xFF5AA9FF).withValues(alpha: 0.25),
          ),
        ),
        Positioned(
          bottom: -90,
          right: -70,
          child: _glassOrb(
            size: 260,
            color: const Color(0xFF4AD2B8).withValues(alpha: 0.22),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child,
      ],
    );
  }

  static Widget _glassOrb({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
