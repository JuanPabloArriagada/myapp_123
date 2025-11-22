import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'listado_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  void _login() {
    if (_emailCtrl.text.contains("@") && _passCtrl.text.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ListaDenunciasScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingrese credenciales válidas")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 100, width: 100,
                  color: Colors.black,
                  child: const Icon(Icons.school, color: Colors.white, size: 50),
                ),
                const SizedBox(height: 30),
                const Text("Iniciar Sesión", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),

                TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "Correo Institucional", prefixIcon: Icon(Icons.email), border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Contraseña", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder())),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0033A0), foregroundColor: Colors.white),
                    onPressed: _login,
                    child: const Text("INGRESAR"),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text("¿No tienes cuenta? Crear una", style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}