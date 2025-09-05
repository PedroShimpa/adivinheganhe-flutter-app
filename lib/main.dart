import 'dart:convert';
import 'package:adivinheganhe/screens/forgot_password_screen.dart';
import 'package:adivinheganhe/screens/perfil_screen.dart';
import 'package:adivinheganhe/services/deep_link_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:adivinheganhe/screens/home_screen.dart';
import 'package:adivinheganhe/screens/login_screen.dart';
import 'package:adivinheganhe/screens/register_screen.dart';
import 'package:adivinheganhe/services/api_service.dart';

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

  Future<void> _initApp() async {
    // Inicializa listener para novos intents
    DeepLinkService.initListener((uri) async {
      await _handleDeepLink(uri);
    });

    // Captura deep link inicial
    final initialUri = await DeepLinkService.getInitialLink();
    if (initialUri != null) {
      await _handleDeepLink(initialUri);
    }

    setState(() {
      _loadingLink = false;
    });
  }

  /// Salva token/user e navega se necessário
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
    } catch (e) {
      print('Erro ao processar deep link: $e');
    }
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

        // Se estiver logado e tentando acessar /login, vai para /home
        if (loggedIn && state.uri.path == '/login') return '/home';

        // Se não estiver logado e tentando acessar /home ou /register, vai para /login
        if (!loggedIn &&
            (state.uri.path == '/home' || state.uri.path == '/register')) {
          return '/login';
        }

        return null; // sem redirecionamento
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
