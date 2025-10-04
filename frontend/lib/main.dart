import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

import 'package:chat_app/screens/splash_screen.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/screens/register_screen.dart';
import 'package:chat_app/screens/chat_screen.dart';

import 'package:chat_app/config/app_route_observer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Chat App',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver], // enables RouteAware callbacks
      home: const SplashScreen(),
      // Optional: centralize routing if needed later
      getPages: const [
        // Example static routes; keep or remove if using only push(MaterialPageRoute)
        // GetPage(name: '/', page: () => SplashScreen()),
        // GetPage(name: '/login', page: () => LoginScreen()),
        // GetPage(name: '/register', page: () => RegisterScreen()),
        // GetPage(name: '/chat', page: () => ChatScreen()),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF412AD5)),
        useMaterial3: true,
      ),
    );
  }
}
