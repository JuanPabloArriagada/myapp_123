import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
// CORRECCIÓN 1: La ruta correcta incluye /services/
import '../services/api_service.dart';

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
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _position = pos);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera);
    setState(() => _image = img);
  }

  Future<void> _enviar() async {
    if (_correoCtrl.text.isEmpty || _descCtrl.text.isEmpty || _image == null || _position == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Faltan datos (foto o ubicación)")));
      return;
    }

    setState(() => _loading = true);
    try {
      // CORRECCIÓN 2: Usar ApiService en lugar de Api
      await ApiService.createDenuncia(
        correo: _correoCtrl.text,
        descripcion: _descCtrl.text,
        photo: _image!,
        lat: _position!.latitude,
        lng: _position!.longitude,
      );
      if(mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if(mounted) setState(() => _loading = false);
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
            TextField(controller: _correoCtrl, decoration: const InputDecoration(labelText: "Correo Institucional")),
            TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: "Descripción del problema")),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.map),
              title: Text(_position == null ? "Obtener Ubicación" : "Ubicación lista: ${_position!.latitude}"),
              onTap: _getLocation,
              tileColor: Colors.grey[200],
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(_image == null ? "Tomar Foto" : "Foto tomada"),
              onTap: _pickImage,
              tileColor: Colors.grey[200],
            ),
            if (_image != null) Padding(padding: const EdgeInsets.all(8.0), child: Image.file(File(_image!.path), height: 100)),
            const SizedBox(height: 20),
            _loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _enviar, child: const Text("ENVIAR DENUNCIA")),
          ],
        ),
      ),
    );
  }
}