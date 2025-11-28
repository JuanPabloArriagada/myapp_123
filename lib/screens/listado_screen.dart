import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'nueva_denuncia_screen.dart';
import 'detalle_screen.dart';
import 'login_screen.dart'; // Necesario para volver al login

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
    _future = ApiService.listDenuncias();
  }

  void _reload() {
    setState(() {
      _future = ApiService.listDenuncias();
    });
  }

  // --- NUEVA FUNCIÓN: CERRAR SESIÓN ---
  void _logout() async {
    await ApiService.logout(); // Borra el token seguro
    if (!mounted) return;

    // Navega al Login y elimina todo el historial de navegación anterior
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Listado de Denuncias"),
        actions: [
          // BOTÓN DE SALIDA
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar Sesión",
            onPressed: _logout,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const NuevaDenunciaScreen()));
          _reload();
        },
      ),
      body: FutureBuilder<List<Denuncia>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          // Si el token expiró (error 401), el ApiService lanza excepción.
          // Podríamos manejarlo aquí para redirigir al login automáticamente.
          if (snapshot.hasError) {
            return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Error: ${snapshot.error}"),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: _reload, child: const Text("Reintentar"))
                  ],
                )
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) return const Center(child: Text("No hay denuncias registradas"));

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: item.imageUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.error)),
                )
                    : const Icon(Icons.image_not_supported),
                title: Text(item.descripcion, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(item.correo),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleDenunciaScreen(denuncia: item)));
                },
              );
            },
          );
        },
      ),
    );
  }
}
