import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// ================= IMPORTANTE =================
// CAMBIA ESTO POR TU NUEVA URL DE NGROK
String kApiBase = "https://ailene-xenodiagnostic-familiarisingly.ngrok-free.dev";
// ==============================================

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

class ApiService {
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
    Uint8List bytes = await photo.readAsBytes();
    String base64Image = base64Encode(bytes);

    final payload = {
      "correo": correo,
      "descripcion": descripcion,
      "foto": base64Image,
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