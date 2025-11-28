import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class NuevaDenunciaScreen extends StatefulWidget {
  const NuevaDenunciaScreen({super.key});
  @override
  State<NuevaDenunciaScreen> createState() => _NuevaDenunciaScreenState();
}

class _NuevaDenunciaScreenState extends State<NuevaDenunciaScreen> {
  // ELIMINADO: final _correoCtrl = TextEditingController(); (Ya no se necesita)
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
    // Validación: Ya no validamos correo aquí
    if (_descCtrl.text.isEmpty || _image == null || _position == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Faltan datos (foto, descripción o ubicación)")));
      return;
    }

    setState(() => _loading = true);
    try {
      // CORRECCIÓN: Ya no enviamos 'correo'. El backend usa el Token.
      await ApiService.createDenuncia(
        descripcion: _descCtrl.text,
        photo: _image!,
        lat: _position!.latitude,
        lng: _position!.longitude,
      );

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Denuncia enviada")));
        Navigator.pop(context);
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
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
            // ELIMINADO: TextField de Correo

            TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: "Descripción del problema",
                    border: OutlineInputBorder()
                )
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.map),
              title: Text(_position == null ? "Obtener Ubicación" : "Ubicación lista"),
              subtitle: _position != null ? Text("Lat: ${_position!.latitude}") : null,
              onTap: _getLocation,
              tileColor: Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(_image == null ? "Tomar Foto" : "Foto tomada"),
              onTap: _pickImage,
              tileColor: Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),

            if (_image != null)
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.file(File(_image!.path), height: 150)
              ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: _loading ? null : _enviar,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15)
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ENVIAR DENUNCIA")
              ),
            ),
          ],
        ),
      ),
    );
  }
}
