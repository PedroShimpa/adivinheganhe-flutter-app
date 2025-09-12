import 'dart:convert';
import 'package:adivinheganhe/screens/forgot_password_screen.dart';
import 'package:adivinheganhe/screens/frinend_request_screen.dart';
import 'package:adivinheganhe/screens/perfil_screen.dart';
import 'package:adivinheganhe/services/deep_link_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:adivinheganhe/screens/home_screen.dart';
import 'package:adivinheganhe/screens/login_screen.dart';
import 'package:adivinheganhe/screens/register_screen.dart';
import 'package:adivinheganhe/services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _loadingLink = true;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  void requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final apiService = ApiService();
      apiService.sendPushToken();
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
    } else {
      return;
    }
  }

  Future<void> _initApp() async {
    DeepLinkService.initListener((uri) async {
      await _handleDeepLink(uri);
    });

    final initialUri = await DeepLinkService.getInitialLink();
    if (initialUri != null) {
      await _handleDeepLink(initialUri);
    }

    final loginState = await _checkLogin();
    final loggedIn = loginState['loggedIn'] ?? false;

    if (loggedIn) {
       requestNotificationPermission();
    }

    setState(() {
      _loadingLink = false;
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    try {
      final token = uri.queryParameters['token'];
      final userJson = uri.queryParameters['user'];
      final route = uri.queryParameters['route'];

      if (token != null && userJson != null) {
        final user = jsonDecode(userJson);
        final apiService = ApiService();
        await apiService.saveToken(token, user);
      }

      if (route != null) {
        final path = route.startsWith('/') ? route : '/$route';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _router.go('/home');
        });
      }
    } catch (e) {}
  }

  Future<Map<String, dynamic>> _checkLogin() async {
    final apiService = ApiService();
    final token = await apiService.getToken();
    final user = await apiService.getUser();
    return {
      'loggedIn': token != null && user != null,
      'user': user,
      'username': user != null ? user['username'] : null,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLink) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    _router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/friend-requests',
          builder: (context, state) => const FriendRequestsScreen(),
        ),

        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/perfil/:username',
          builder: (context, state) {
            final username = state.pathParameters['username']!;
            return PerfilScreen(username: username);
          },
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
      ],
      redirect: (context, state) async {
        final loginState = await _checkLogin();
        final loggedIn = loginState['loggedIn'] ?? false;

        if (loggedIn &&
            (state.uri.path == '/login' || state.uri.path == '/register')) {
          return '/home';
        }

        final isProtectedRoute =
            state.uri.path.startsWith('/home') ||
            state.uri.path.startsWith('/perfil');
        if (!loggedIn && isProtectedRoute) {
          return '/login';
        }

        return null;
      },
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Adivinhe e Ganhe',
      theme: ThemeData.light(),
      routerConfig: _router,
    );
  }
}
