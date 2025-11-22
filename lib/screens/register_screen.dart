import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  void _register() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cuenta creada con éxito")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
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

                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: "Nombre Completo", border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? "Requerido" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailCtrl,
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

                ElevatedButton(onPressed: _register, child: const Text("Registrarse")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}