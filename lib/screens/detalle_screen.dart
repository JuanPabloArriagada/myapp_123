import 'package:flutter/material.dart';
// CORRECCIÓN: Apuntar a la carpeta services
import '../services/api_service.dart';

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
              Center(child: Image.network(denuncia.imageUrl, height: 200, fit: BoxFit.cover)),
            const SizedBox(height: 20),
            Text("Correo: ${denuncia.correo}", style: const TextStyle(fontWeight: FontWeight.bold)),
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