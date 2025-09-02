import 'package:flutter/material.dart';
import 'package:adivinheganhe/screens/home_screen.dart';
import 'package:adivinheganhe/screens/login_screen.dart';
import 'package:adivinheganhe/services/api_service.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
// }

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // const AndroidInitializationSettings initializationSettingsAndroid =
  //     AndroidInitializationSettings('@mipmap/ic_launcher');
  // const InitializationSettings initializationSettings = InitializationSettings(
  //   android: initializationSettingsAndroid,
  // );
  // await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // // Background message
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // late final FirebaseMessaging _messaging;
  // String? _fcmToken;

  @override
  void initState() {
    super.initState();
    // _setupFirebaseMessaging();
  }

  // Future<void> _setupFirebaseMessaging() async {
  //   _messaging = FirebaseMessaging.instance;

  //   // Solicitar permissão para iOS
  //   NotificationSettings settings = await _messaging.requestPermission(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   );

  //   // Obter token do dispositivo
  //   _fcmToken = await _messaging.getToken();

  //   // Escuta mensagens enquanto o app está aberto
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     RemoteNotification? notification = message.notification;
  //     AndroidNotification? android = message.notification?.android;

  //     if (notification != null && android != null) {
  //       flutterLocalNotificationsPlugin.show(
  //         notification.hashCode,
  //         notification.title,
  //         notification.body,
  //         NotificationDetails(
  //           android: AndroidNotificationDetails(
  //             'default_channel',
  //             'Notificações',
  //             channelDescription: 'Canal padrão de notificações',
  //             importance: Importance.max,
  //             priority: Priority.high,
  //             playSound: true,
  //           ),
  //         ),
  //       );
  //     }
  //   });
  // }

  Future<Map<String, dynamic>> _checkLogin() async {
    final apiService = ApiService();
    final token = await apiService.getToken();
    final user = await apiService.getUser();

    return {
      'loggedIn': token != null,
      'user': user,
      'username': user != null ? user['username'] : null,
    };
  }

  // main.dart

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

          // This part correctly routes the user on startup
          return loggedIn
              ? HomeScreen(loggedIn: true, user: user, username: username)
              : const LoginScreen();
        },
      ),
      // CORRECTED ROUTES MAP
      routes: {
        '/login': (_) => const LoginScreen(),
        // The '/home' route should not try to access variables from the FutureBuilder.
        // It's used for named navigation from other parts of the app.
        '/home':
            (_) => const HomeScreen(
              loggedIn:
                  false, // Assuming if you navigate to '/home', the user is logged in.
              user:
                  null, // Data would need to be re-fetched or managed by a state solution.
              username: null,
            ),
      },
    );
  }
}
