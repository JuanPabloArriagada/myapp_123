import 'package:flutter/material.dart';
// CORRECCIÓN DE RUTA
import '../services/api_service.dart';
import 'nueva_denuncia_screen.dart';
import 'detalle_screen.dart';

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
    // CORRECCIÓN DE NOMBRE DE CLASE (ApiService)
    _future = ApiService.listDenuncias();
  }

  void _reload() {
    setState(() {
      _future = ApiService.listDenuncias();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Listado de Denuncias")),
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
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

          final items = snapshot.data ?? [];
          if (items.isEmpty) return const Center(child: Text("No hay denuncias"));

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: item.imageUrl.isNotEmpty
                    ? Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.error))
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