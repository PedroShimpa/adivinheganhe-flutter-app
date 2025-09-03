import 'package:flutter/material.dart';
import 'package:adivinheganhe/screens/home_screen.dart';
import 'package:adivinheganhe/screens/login_screen.dart';
import 'package:adivinheganhe/screens/register_screen.dart'; // <- IMPORTA A TELA DE REGISTRO
import 'package:adivinheganhe/services/api_service.dart';
import 'package:firebase_core/firebase_core.dart';

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
      home: FutureBuilder<Map<String, dynamic>>(
        future: _checkLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text("Erro ao carregar dados.")),
            );
          }

          final bool loggedIn = snapshot.data?['loggedIn'] ?? false;
          final user = snapshot.data?['user'];
          final username = snapshot.data?['username'];

          return loggedIn
              ? HomeScreen()
              : const LoginScreen();
        },
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => FutureBuilder<Map<String, dynamic>>(
              future: _checkLogin(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data?['loggedIn'] != true) {
                  return const LoginScreen();
                }

                final user = snapshot.data?['user'];
                final username = snapshot.data?['username'];

                return HomeScreen(
                );
              },
            ),
        '/register': (_) => const RegisterScreen(), // <- ADICIONADO
      },
    );
  }
}
