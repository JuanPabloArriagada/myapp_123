import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Necesario para leer token

import 'screens/login_screen.dart';
import 'screens/listado_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
    _secureScreen();
  }

  Future<void> _secureScreen() async {
    try {
      await ScreenProtector.protectDataLeakageOn();
    } catch (e) {
      print("Error al bloquear capturas: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Denuncias Seguras',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      // En lugar de ir directo al Login, vamos a una pantalla de chequeo
      home: const CheckAuthScreen(),
    );
  }
}

// --- NUEVA PANTALLA INTERMEDIA DE CARGA ---
class CheckAuthScreen extends StatefulWidget {
  const CheckAuthScreen({super.key});

  @override
  State<CheckAuthScreen> createState() => _CheckAuthScreenState();
}

class _CheckAuthScreenState extends State<CheckAuthScreen> {

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Pequeña espera artificial para que se vea el logo (opcional)
    await Future.delayed(const Duration(milliseconds: 1500));

    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'jwt_token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // SI HAY TOKEN -> Vamos directo al Listado
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ListaDenunciasScreen())
      );
    } else {
      // NO HAY TOKEN -> Vamos al Login
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga con logo mientras verifica
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100, width: 100,
              color: Colors.black,
              child: const Icon(Icons.school, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text("Verificando sesión segura..."),
          ],
        ),
      ),
    );
  }
}
