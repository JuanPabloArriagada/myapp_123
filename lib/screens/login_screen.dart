import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'listado_screen.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Variable para controlar el estado de carga (círculo girando)
  bool _isLoading = false;

  void _login() async {
    // 1. Validación básica local
    if (!_emailCtrl.text.contains("@") || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor ingrese credenciales válidas")),
      );
      return;
    }

    // 2. Activar indicador de carga
    setState(() {
      _isLoading = true;
    });

    // 3. Llamada al servicio real (Backend)
    // Esto devuelve true si el token se guardó correctamente
    final success = await ApiService.login(_emailCtrl.text, _passCtrl.text);

    // 4. Desactivar carga
    setState(() {
      _isLoading = false;
    });

    // 5. Verificar si el widget sigue activo antes de usar el contexto
    if (!mounted) return;

    if (success) {
      // Login exitoso: Navegar a la lista
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ListaDenunciasScreen()),
      );
    } else {
      // Login fallido: Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Credenciales incorrectas o error de conexión"),
          backgroundColor: Colors.red,
        ),
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

                const Text(
                    "Iniciar Sesión",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 30),

                TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: "Correo Institucional",
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder()
                    )
                ),
                const SizedBox(height: 15),

                TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder()
                    )
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0033A0),
                        foregroundColor: Colors.white
                    ),
                    // Si está cargando, desactivamos el botón (null)
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                        : const Text("INGRESAR"),
                  ),
                ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen())
                  ),
                  child: const Text(
                      "¿No tienes cuenta? Crear una",
                      style: TextStyle(color: Colors.blue)
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
