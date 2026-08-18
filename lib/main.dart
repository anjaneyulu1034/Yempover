import 'package:yempover_app/services/notification1_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'utils/notification_provider.dart';
import 'utils/chat_provider.dart';
import 'models/ProductPostmain.dart';
import 'screens/Home_screen.dart';
import 'screens/LoginScreen.dart';
import 'screens/OnboardingScreen.dart';
import 'screens/PostDetailScreen.dart';
import 'screens/tradechatscreen/ChatDetailScreen.dart';
import 'services/api_service.dart';
import 'services/resume_state_service.dart';
import 'services/shared_prefs_service.dart';
import 'services/token_service.dart';
import 'services/trade_chat_service/trade_chat_service.dart';
import 'widgets/location_permission_gate.dart';
import 'widgets/subscription_resume_gate.dart';

// Global notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

/// 🔥 Background message handler
/// MUST be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 🔥 Required for background messages
  await Firebase.initializeApp();
  debugPrint("📩 Background message received: ${message.messageId}");
}

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep the native launch screen on screen (instead of a separate Flutter
  // splash widget) until we've resolved where the user should land.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 🔥 STEP 1: Initialize Firebase FIRST
  await Firebase.initializeApp();

  // 🔥 STEP 2: Set background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🔥 STEP 3: Initialize notification service
  try {
    await NotificationService1().init();
  } catch (e) {
    debugPrint('Notification init failed (continuing app launch): $e');
  }

  // 🔥 STEP 4: Resolve the first screen (was previously SplashScreen's job)
  final initialScreen = await _resolveInitialScreen();

  // 🔥 STEP 5: Run app
  runApp(MyApp(initialScreen: initialScreen));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService1.flushPendingNavigation();
    FlutterNativeSplash.remove();
    _restoreLastScreen();
  });
}

/// Decides which screen the app should open on, based on auth/onboarding
/// state — the same decision `SplashScreen` used to make, minus the extra
/// screen: the native launch screen stays up (via `preserve()` above) while
/// this runs, so there's no second splash to show it on top of.
Future<Widget> _resolveInitialScreen() async {
  try {
    final isLoggedIn = await TokenService().isLoggedIn();
    final isGuestUser = await TokenService().isGuestUser();

    if (isLoggedIn || isGuestUser) {
      debugPrint('🟢 main: User is authenticated or guest, opening Home');
      return const HomeScreen();
    }

    final hasSeenOnboarding = await SharedPrefsService.hasSeenOnboarding();
    if (!hasSeenOnboarding) {
      debugPrint('🟢 main: First time user, opening Onboarding');
      return const OnboardingScreen();
    }

    debugPrint('🟢 main: Returning user, opening Login');
    return const LoginScreen();
  } catch (e) {
    debugPrint('🔴 main: Error checking login status: $e');
    // On error, default to onboarding for safety.
    return const OnboardingScreen();
  }
}

/// Reopens the chat/post the user last had open, if the app recorded one
/// (only true when the process was killed mid-screen rather than the user
/// backing out normally — see [ResumeStateService]). Any failure here
/// (deleted chat/post, network error, etc.) just leaves the user on Home
/// rather than surfacing an error for something they didn't ask for. A
/// no-op if there's no resume record, so it's safe to call unconditionally.
Future<void> _restoreLastScreen() async {
  try {
    final record = await ResumeStateService.read();
    if (record == null) return;

    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;

    final type = record['type'];
    final id = record['id'];
    if (id == null || id.isEmpty) return;

    if (type == 'chat') {
      final currentUserId = await TokenService().getUserId();
      if (currentUserId == null || currentUserId.isEmpty) return;

      final chat = await TradeChatService().getChatById(id);
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chat: chat,
            currentUserId: currentUserId,
            onChatUpdated: (_) {},
          ),
        ),
      );
    } else if (type == 'post') {
      final isService = record['isService'] == 'true';
      final response = await ApiService().getPostDetail(
        postId: id,
        type: isService ? PostType.service : PostType.product,
      );
      navigator.push(
        MaterialPageRoute(
          builder: (_) =>
              PostDetailScreen(post: response.post, userItems: const []),
        ),
      );
    }
  } catch (e) {
    debugPrint('🟡 main: Could not restore last screen: $e');
  } finally {
    // Consume the record either way — don't keep retrying a broken restore
    // on every future cold start.
    await ResumeStateService.clear();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialScreen});

  final Widget initialScreen;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        title: 'BarterX',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF1A73E8),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: _NoAnimationPageTransitionsBuilder(),
              TargetPlatform.iOS: _NoAnimationPageTransitionsBuilder(),
              TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
              TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
              TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
              TargetPlatform.fuchsia: _NoAnimationPageTransitionsBuilder(),
            },
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A73E8),
            primary: const Color(0xFF1A73E8),
            surface: Colors.white,
            surfaceContainerHigh: Colors.white,
          ),
          fontFamily: 'Roboto',
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            titleSpacing: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            foregroundColor: Colors.black,
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              height: 1.2,
              overflow: TextOverflow.ellipsis,
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
            fillColor: const Color(0xFFF5F5F5),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFF1A73E8), width: 1.5),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
            floatingLabelStyle: const TextStyle(
              color: Color(0xFF1A73E8),
              fontWeight: FontWeight.w600,
            ),
            labelStyle: TextStyle(color: Colors.grey.shade600),
            hintStyle: TextStyle(color: Colors.grey.shade500),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 50),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.2,
                overflow: TextOverflow.ellipsis,
              ),
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
              minimumSize: const Size(0, 48),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.2,
                overflow: TextOverflow.ellipsis,
              ),
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
          final content = child ?? const SizedBox.shrink();

          return LocationPermissionGate(
            child: SubscriptionResumeGate(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  final currentFocus = FocusManager.instance.primaryFocus;
                  if (currentFocus == null || !currentFocus.hasFocus) return;

                  // Don't dismiss when the tap landed on the focused field
                  // itself (e.g. repositioning the cursor) — only when it's
                  // genuinely outside, which is what should close the
                  // keyboard on devices with no visible/gesture back button.
                  final renderObject = currentFocus.context?.findRenderObject();
                  if (renderObject is RenderBox && renderObject.attached) {
                    final topLeft = renderObject.localToGlobal(Offset.zero);
                    final bounds = topLeft & renderObject.size;
                    if (bounds.contains(event.position)) return;
                  }

                  currentFocus.unfocus();
                },
                child: content,
              ),
            ),
          );
        },
        home: initialScreen,
      ),
    );
  }
}
