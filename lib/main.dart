import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:login_bear_animation/firebase_options.dart';
import 'package:login_bear_animation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase inicializado con éxito y conectado correctamente ✅");
  } catch (e) {
    debugPrint("Error al inicializar Firebase: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login Bear Animation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}