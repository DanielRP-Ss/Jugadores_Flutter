import 'package:flutter/material.dart';
import '../models/videojuego.dart';
import '../services/api_service.dart';
import 'jugadores_screen.dart';
import 'registro_screen.dart';

class VideojuegosScreen extends StatefulWidget {
  const VideojuegosScreen({super.key});

  @override
  State<VideojuegosScreen> createState() => _VideojuegosScreenState();
}

class _VideojuegosScreenState extends State<VideojuegosScreen> {
  final ApiService _api = ApiService();
  late Future<List<Videojuego>> _future;
  String _plataforma = '';

  @override
  void initState() {
    super.initState();
    _future = _api.fetchVideojuegos(); // se dispara una sola vez
  }

  void _recargar({String? plataforma}) {
    setState(() {
      _plataforma = plataforma ?? _plataforma;
      _future = _api.fetchVideojuegos(plataforma: _plataforma.isEmpty ? null : _plataforma);
    });
  }

  /// Diálogo de login admin: POST /api/token/ → guarda el token en ApiService.
  void _mostrarLogin() {
    final user = TextEditingController();
    final pass = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login administrador'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: user,
            decoration: const InputDecoration(labelText: 'Usuario'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: pass,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contraseña'),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final token = await _api.login(user.text.trim(), pass.text);
                _api.setToken(token);
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sesión admin iniciada — ya puede registrar jugadores')),
                );
              } on ApiException catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${e.status}: ${e.message}'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de videojuegos'),
        actions: [
          // Vista de jugadores registrados (paginada)
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Jugadores',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JugadoresScreen(api: _api)),
            ),
          ),
          // Login admin — sin esto el POST de jugadores devuelve 403
          IconButton(
            icon: const Icon(Icons.login),
            tooltip: 'Login admin',
            onPressed: _mostrarLogin,
          ),
          // Filtro por plataforma — query param ?plataforma= de la API
          DropdownButton<String>(
            value: _plataforma.isEmpty ? null : _plataforma,
            hint: const Text('Plataforma', style: TextStyle(color: Colors.white70)),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: '', child: Text('Todas')),
              DropdownMenuItem(value: 'PC', child: Text('PC')),
              DropdownMenuItem(value: 'PlayStation', child: Text('PlayStation')),
              DropdownMenuItem(value: 'Xbox', child: Text('Xbox')),
              DropdownMenuItem(value: 'Nintendo', child: Text('Nintendo')),
            ],
            onChanged: (v) => _recargar(plataforma: v ?? ''),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<List<Videojuego>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // estado: cargando
          }
          if (snapshot.hasError) {
            return Center( // estado: error (p. ej. Django apagado o 400 por ALLOWED_HOSTS)
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                Text('${snapshot.error}'),
                const SizedBox(height: 12),
                FilledButton(onPressed: _recargar, child: const Text('Reintentar')),
              ]),
            );
          }
          final juegos = snapshot.data!;
          if (juegos.isEmpty) {
            return const Center(child: Text('No hay videojuegos para esta plataforma'));
          }
          return RefreshIndicator( // pull-to-refresh recarga la petición
            onRefresh: () async => _recargar(),
            child: ListView.builder(
              itemCount: juegos.length,
              itemBuilder: (_, i) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.sports_esports),
                  title: Text(juegos[i].nombre),
                  subtitle: Text('${juegos[i].genero} · ${juegos[i].plataforma}'),
                  trailing: Chip(label: Text(juegos[i].clasificacion)),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RegistroScreen(api: _api)),
          );
          _recargar(); // al volver del formulario recarga el catálogo
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Registro'),
      ),
    );
  }
}
