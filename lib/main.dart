import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

// ================= CONFIGURACIÓN =================
// IMPORTANTE: Aquí pondrás la URL que te de Ngrok más adelante.
// Ejemplo: "https://a1b2-c3d4.ngrok-free.app"
String kApiBase =
    "https://ailene-xenodiagnostic-familiarisingly.ngrok-free.dev";

// ================= MODELO DENUNCIA =================
class Denuncia {
  final int id;
  final String correo;
  final String descripcion;
  final String imageUrl;
  final double? lat;
  final double? lng;

  Denuncia({
    required this.id,
    required this.correo,
    required this.descripcion,
    required this.imageUrl,
    this.lat,
    this.lng,
  });

  factory Denuncia.fromJson(Map<String, dynamic> j) {
    var ubi = j['ubicacion'] ?? {};
    return Denuncia(
      id: j['id'],
      correo: j['correo'],
      descripcion: j['descripcion'],
      imageUrl: j['image_url'] ?? '',
      lat: ubi['lat'],
      lng: ubi['lng'],
    );
  }
}

// ================= SERVICIO API =================
class Api {
  static Future<List<Denuncia>> listDenuncias() async {
    final r = await http.get(Uri.parse("$kApiBase/api/denuncias"));
    if (r.statusCode != 200) throw Exception("Error API: ${r.statusCode}");

    final data = jsonDecode(r.body) as List;
    return data.map((e) => Denuncia.fromJson(e)).toList();
  }

  static Future<void> createDenuncia({
    required String correo,
    required String descripcion,
    required XFile photo,
    required double lat,
    required double lng,
  }) async {
    // Convertir imagen a Base64
    Uint8List bytes = await photo.readAsBytes();
    String base64Image = base64Encode(bytes);

    final payload = {
      "correo": correo,
      "descripcion": descripcion,
      "foto": base64Image, // Según PDF source 336
      "ubicacion": {"lat": lat, "lng": lng},
    };

    final r = await http.post(
      Uri.parse("$kApiBase/api/denuncias"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (r.statusCode != 201) {
      throw Exception("Error creando: ${r.body}");
    }
  }
}

// ================= APP PRINCIPAL =================
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Denuncias Duoc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      // CAMBIO: Ahora arranca en LoginScreen
      home: const LoginScreen(),
    );
  }
}

// ================= PANTALLA 1: LISTADO =================
class ListaDenunciasScreen extends StatefulWidget {
  const ListaDenunciasScreen({super.key});
  @override
  State<ListaDenunciasScreen> createState() => _ListaDenunciasScreenState();
}

class _ListaDenunciasScreenState extends State<ListaDenunciasScreen> {
  late Future<List<Denuncia>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.listDenuncias();
  }

  void _reload() {
    setState(() {
      _future = Api.listDenuncias();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Listado de Denuncias")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NuevaDenunciaScreen()),
          );
          _reload(); // Recargar al volver
        },
      ),
      body: FutureBuilder<List<Denuncia>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text("No hay denuncias"));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.error),
                      )
                    : const Icon(Icons.image_not_supported),
                title: Text(
                  item.descripcion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(item.correo),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetalleDenunciaScreen(denuncia: item),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ================= PANTALLA 2: DETALLE =================
class DetalleDenunciaScreen extends StatelessWidget {
  final Denuncia denuncia;
  const DetalleDenunciaScreen({super.key, required this.denuncia});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detalle Denuncia")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (denuncia.imageUrl.isNotEmpty)
              Center(
                child: Image.network(
                  denuncia.imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),
            Text(
              "Correo: ${denuncia.correo}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Descripción:\n${denuncia.descripcion}"),
            const SizedBox(height: 10),
            Text("Ubicación: Lat ${denuncia.lat}, Lng ${denuncia.lng}"),
          ],
        ),
      ),
    );
  }
}

// ================= PANTALLA 3: NUEVA DENUNCIA =================
class NuevaDenunciaScreen extends StatefulWidget {
  const NuevaDenunciaScreen({super.key});
  @override
  State<NuevaDenunciaScreen> createState() => _NuevaDenunciaScreenState();
}

class _NuevaDenunciaScreenState extends State<NuevaDenunciaScreen> {
  final _correoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  XFile? _image;
  Position? _position;
  bool _loading = false;

  Future<void> _getLocation() async {
    // Solicitar permiso básico (para el examen suele bastar con esto rápido)
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _position = pos);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera); // O gallery
    setState(() => _image = img);
  }

  Future<void> _enviar() async {
    if (_correoCtrl.text.isEmpty ||
        _descCtrl.text.isEmpty ||
        _image == null ||
        _position == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Faltan datos (foto o ubicación incluidos)"),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    String? errorMessage;
    bool success = false;

    try {
      await Api.createDenuncia(
        correo: _correoCtrl.text,
        descripcion: _descCtrl.text,
        photo: _image!,
        lat: _position!.latitude,
        lng: _position!.longitude,
      );
      success = true;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else if (errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Denuncia")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _correoCtrl,
              decoration: const InputDecoration(
                labelText: "Correo Institucional",
              ),
            ),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: "Descripción del problema",
              ),
            ),
            const SizedBox(height: 20),

            // Botón Ubicación
            ListTile(
              leading: const Icon(Icons.map),
              title: Text(
                _position == null
                    ? "Obtener Ubicación"
                    : "Ubicación lista: ${_position!.latitude}",
              ),
              onTap: _getLocation,
              tileColor: Colors.grey[200],
            ),
            const SizedBox(height: 10),

            // Botón Foto
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(_image == null ? "Tomar Foto" : "Foto tomada"),
              onTap: _pickImage,
              tileColor: Colors.grey[200],
            ),
            if (_image != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.file(File(_image!.path), height: 100),
              ),

            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _enviar,
                    child: const Text("ENVIAR DENUNCIA"),
                  ),
          ],
        ),
      ),
    );
  }
}

// ================= PANTALLA: LOGIN (Imagen 1 PDF) =================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  void _login() {
    // Aquí podrías validar con el backend si fuera requisito,
    // pero para esta prueba basta con navegar al listado.
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
                // Logo simulado (puedes usar un Icon o Image.asset)
                Container(
                  height: 100,
                  width: 100,
                  color: Colors.black, // Negro como en el PDF
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Iniciar Sesión",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Bienvenido de vuelta",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // Campo Correo
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: "Correo Institucional",
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                    hintText: "ejemplo@duoc.cl",
                  ),
                ),
                const SizedBox(height: 15),

                // Campo Contraseña
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(),
                    hintText: "Ingresa tu contraseña",
                    suffixIcon: Icon(Icons.visibility_outlined),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text("Olvidé mi contraseña"),
                  ),
                ),
                const SizedBox(height: 10),

                // Botón Grande Azul
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF0033A0,
                      ), // Azul oscuro tipo Duoc
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _login,
                    child: const Text(
                      "Iniciar Sesión",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("¿No tienes cuenta? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Crear una",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= PANTALLA: REGISTRO (Imagen 2 PDF) =================
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
      // Simular registro exitoso y volver al login o entrar directo
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cuenta creada con éxito")));
      Navigator.pop(context); // Vuelve al Login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    color: const Color(0xFF002D4B),
                    child: const Icon(Icons.person_add, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Crear Cuenta",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Ingresa tus datos para comenzar",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // Campos del formulario
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Nombre Completo",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Campo requerido" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: "Correo Institucional",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        !v!.contains("@duoc") ? "Debe ser correo Duoc" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v!.length < 6 ? "Mínimo 6 caracteres" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirmar Contraseña",
                      prefixIcon: Icon(Icons.lock_clock),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v != _passCtrl.text
                        ? "Las contraseñas no coinciden"
                        : null,
                  ),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0033A0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _register,
                      child: const Text(
                        "Registrarse",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("¿Ya tienes cuenta? "),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Inicia sesión",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
