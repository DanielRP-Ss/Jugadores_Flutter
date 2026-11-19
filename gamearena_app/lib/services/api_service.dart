import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/videojuego.dart';
import '../models/jugador.dart';

/// Excepción con el status HTTP para distinguir 403/400/500 en la UI.
class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);

  @override
  String toString() => '[$status] $message';
}

/// Modelo de la respuesta paginada de /api/jugadores/ y /api/torneos/.
class PaginaJugadores {
  final int paginaActual;
  final int totalPaginas;
  final int totalRegistros;
  final List<Jugador> resultados;

  PaginaJugadores({
    required this.paginaActual,
    required this.totalPaginas,
    required this.totalRegistros,
    required this.resultados,
  });

  factory PaginaJugadores.fromJson(Map<String, dynamic> json) => PaginaJugadores(
        paginaActual: json['pagina_actual'],
        totalPaginas: json['total_paginas'],
        totalRegistros: json['total_registros'],
        resultados: (json['resultados'] as List).map((j) => Jugador.fromJson(j)).toList(),
      );
}

class ApiService {
  /// 10.0.2.2 = localhost de la PC vista desde el emulador Android.
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  String? _token;

  bool get estaAutenticado => _token != null;

  void setToken(String token) => _token = token;

  /// POST /api/token/ → devuelve el token si las credenciales son válidas.
  Future<String> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['token'];
    }
    throw ApiException(res.statusCode, 'Credenciales inválidas');
  }

  /// GET /api/videojuegos/ — filtro opcional por plataforma.
  Future<List<Videojuego>> fetchVideojuegos({String? plataforma}) async {
    var url = '$baseUrl/videojuegos/';
    if (plataforma != null && plataforma.isNotEmpty) {
      url += '?plataforma=${Uri.encodeQueryComponent(plataforma)}';
    }
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => Videojuego.fromJson(j)).toList();
    }
    throw ApiException(res.statusCode, 'Error al cargar videojuegos');
  }

  /// GET /api/jugadores/ — RESPUESTA PAGINADA por el backend (5 por página).
  /// Soporta búsqueda parcial por nickname (?buscar=) y número de página.
  Future<PaginaJugadores> fetchJugadores({int page = 1, String buscar = ''}) async {
    var url = '$baseUrl/jugadores/?page=$page';
    if (buscar.isNotEmpty) {
      url += '&buscar=${Uri.encodeQueryComponent(buscar)}';
    }
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      return PaginaJugadores.fromJson(jsonDecode(res.body));
    }
    throw ApiException(res.statusCode, 'Error al cargar jugadores');
  }

  /// POST /api/jugadores/ — requiere usuario admin (token), si no: 403.
  Future<Jugador> registrarJugador({
    required String nickname,
    required String nombre,
    required String email,
    required String pais,
    required int nivel,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/jugadores/'),
      headers: {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Token $_token',
      },
      body: jsonEncode({
        'nickname': nickname,
        'nombre': nombre,
        'email': email,
        'pais': pais,
        'nivel': nivel,
        'activo': true,
      }),
    );
    if (res.statusCode == 201) {
      return Jugador.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 403) {
      throw ApiException(403, 'Se requiere un usuario administrador');
    }
    if (res.statusCode == 400) {
      final errores = jsonDecode(res.body) as Map<String, dynamic>;
      final primer = errores.entries.first;
      throw ApiException(400, '${primer.key}: ${(primer.value as List).first}');
    }
    throw ApiException(res.statusCode, 'Error inesperado del servidor');
  }
}
