import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Importamos el servicio

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false; // Para mostrar carga

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // LLAMADA REAL AL SERVIDOR
        final success = await ApiService.register(
            _emailCtrl.text.trim(),
            _passCtrl.text.trim()
        );

        if (!mounted) return;

        setState(() => _isLoading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Cuenta creada. ¡Ahora inicia sesión!"),
                backgroundColor: Colors.green,
              )
          );
          Navigator.pop(context); // Volver al login
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error: El correo ya existe o falló la conexión"))
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black)
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.person_add, size: 60, color: Color(0xFF002D4B)),
                const SizedBox(height: 20),
                const Text("Crear Cuenta", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),

                // NO PEDIMOS NOMBRE (El backend actual solo usa email/pass para simplificar JWT)

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Correo", border: OutlineInputBorder()),
                  validator: (v) => !v!.contains("@") ? "Correo inválido" : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Contraseña", border: OutlineInputBorder()),
                  validator: (v) => v!.length < 6 ? "Mínimo 6 caracteres" : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Confirmar", border: OutlineInputBorder()),
                  validator: (v) => v != _passCtrl.text ? "No coinciden" : null,
                ),
                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("REGISTRARSE"),
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
