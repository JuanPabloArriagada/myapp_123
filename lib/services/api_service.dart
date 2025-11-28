import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Importar Secure Storage

// CAMBIA ESTO POR TU URL DE NGROK
String kApiBase = "https://ailene-xenodiagnostic-familiarisingly.ngrok-free.dev";

class Denuncia {
  final int id;
  final String correo;
  final String descripcion;
  final String imageUrl;
  final double? lat;
  final double? lng;

  Denuncia({required this.id, required this.correo, required this.descripcion, required this.imageUrl, this.lat, this.lng});

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
  // Instancia de Secure Storage
  static const _storage = FlutterSecureStorage();

  // 1. LOGIN (Guardamos el token)
  static Future<bool> login(String email, String password) async {
    final r = await http.post(
      Uri.parse("$kApiBase/api/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (r.statusCode == 200) {
      final data = jsonDecode(r.body);
      // GUARDAR TOKEN DE FORMA SEGURA
      await _storage.write(key: 'jwt_token', value: data['access_token']);
      return true;
    }
    return false;
  }

  // 2. REGISTRO (Nuevo)
  static Future<bool> register(String email, String password) async {
    final r = await http.post(
      Uri.parse("$kApiBase/api/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    return r.statusCode == 201;
  }

  // 3. LOGOUT
  static Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  // Método auxiliar para obtener headers con Token
  static Future<Map<String, String>> _getHeaders() async {
    String? token = await _storage.read(key: 'jwt_token');
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token", // INYECTAMOS EL TOKEN AQUÍ
    };
  }

  // LISTAR (Protegido)
  static Future<List<Denuncia>> listDenuncias() async {
    final headers = await _getHeaders();
    final r = await http.get(Uri.parse("$kApiBase/api/denuncias"), headers: headers);

    if (r.statusCode == 401) throw Exception("Sesión expirada");
    if (r.statusCode != 200) throw Exception("Error API: ${r.statusCode}");

    final data = jsonDecode(r.body) as List;
    return data.map((e) => Denuncia.fromJson(e)).toList();
  }

  // CREAR (Protegido)
  static Future<void> createDenuncia({
    required String descripcion,
    required XFile photo,
    required double lat,
    required double lng,
  }) async {
    Uint8List bytes = await photo.readAsBytes();
    String base64Image = base64Encode(bytes);

    final payload = {
      "descripcion": descripcion,
      "foto": base64Image,
      "ubicacion": {"lat": lat, "lng": lng},
    };

    final headers = await _getHeaders();
    final r = await http.post(
      Uri.parse("$kApiBase/api/denuncias"),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (r.statusCode != 201) {
      throw Exception("Error creando: ${r.body}");
    }
  }
}
