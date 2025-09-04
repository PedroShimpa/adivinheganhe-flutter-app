import 'package:flutter/material.dart';
import 'package:adivinheganhe/screens/home_screen.dart';
import 'package:adivinheganhe/screens/login_screen.dart';
import 'package:adivinheganhe/screens/register_screen.dart';
import 'package:adivinheganhe/services/api_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

Future<void> main() async {
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
  Uri? _initialLink;

  @override
  void initState() {
    super.initState();
    _getInitialLink();
  }

  Future<void> _getInitialLink() async {
    try {
      if (Platform.isAndroid) {
        final uri = await MethodChannel('deep_link_channel')
            .invokeMethod<String>('getInitialLink');
        if (uri != null) {
          setState(() {
            _initialLink = Uri.parse(uri);
          });
        }
      }
    } catch (e) {
      // ignore
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Adivinhe e Ganhe',
      theme: ThemeData.light(),
      home: Builder(builder: (context) {
        print('link abertura');
        print(_initialLink);
        if (_initialLink != null &&
            _initialLink.toString().startsWith('adivinheganhe://home')) {
          return const HomeScreen();
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: _checkLogin(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            final loggedIn = snapshot.data?['loggedIn'] ?? false;
            return loggedIn ? HomeScreen() : const LoginScreen();
          },
        );
      }),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/register': (_) => const RegisterScreen(),
      },
    );
  }
}
