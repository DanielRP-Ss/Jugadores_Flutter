class Videojuego {
  final int id;
  final String nombre;
  final String genero;
  final String plataforma;
  final String clasificacion;

  Videojuego({
    required this.id,
    required this.nombre,
    required this.genero,
    required this.plataforma,
    required this.clasificacion,
  });

  factory Videojuego.fromJson(Map<String, dynamic> json) => Videojuego(
        id: json['id'],
        nombre: json['nombre'],
        genero: json['genero'],
        plataforma: json['plataforma'],
        clasificacion: json['clasificacion'] ?? 'Sin clasificar',
      );
}
