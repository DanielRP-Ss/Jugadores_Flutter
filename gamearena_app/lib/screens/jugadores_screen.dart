import 'package:flutter/material.dart';
import '../models/jugador.dart';
import '../services/api_service.dart';

class JugadoresScreen extends StatefulWidget {
  final ApiService api;
  const JugadoresScreen({super.key, required this.api});

  @override
  State<JugadoresScreen> createState() => _JugadoresScreenState();
}

class _JugadoresScreenState extends State<JugadoresScreen> {
  late Future<PaginaJugadores> _future;
  int _pagina = 1;
  String _buscar = '';

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchJugadores(page: _pagina);
  }

  void _cargar({int? pagina, String? buscar}) {
    setState(() {
      _pagina = pagina ?? _pagina;
      _buscar = buscar ?? _buscar;
      _future = widget.api.fetchJugadores(page: _pagina, buscar: _buscar);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jugadores registrados')),
      body: Column(children: [
        // Búsqueda por nickname (?buscar=)
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar por nickname...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (v) => _cargar(pagina: 1, buscar: v.trim()),
          ),
        ),
        Expanded(
          child: FutureBuilder<PaginaJugadores>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${snapshot.error}'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => _cargar(),
                      child: const Text('Reintentar'),
                    ),
                  ]),
                );
              }
              final pagina = snapshot.data!;
              if (pagina.resultados.isEmpty) {
                return const Center(child: Text('Sin resultados'));
              }
              return Column(children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: pagina.resultados.length,
                    itemBuilder: (_, i) {
                      final Jugador j = pagina.resultados[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text(j.nickname[0].toUpperCase())),
                        title: Text(j.nickname),
                        subtitle: Text('${j.nombre} · ${j.pais}'),
                        trailing: Chip(label: Text('Nv. ${j.nivel}')),
                      );
                    },
                  ),
                ),
                // Controles de paginación del backend
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: pagina.paginaActual > 1
                            ? () => _cargar(pagina: pagina.paginaActual - 1)
                            : null,
                      ),
                      Text('Página ${pagina.paginaActual} de ${pagina.totalPaginas} '
                          '(${pagina.totalRegistros} jugadores)'),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: pagina.paginaActual < pagina.totalPaginas
                            ? () => _cargar(pagina: pagina.paginaActual + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}
