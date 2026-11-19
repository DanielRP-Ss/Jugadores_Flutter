class Jugador {
  final int id;
  final String nickname;
  final String nombre;
  final String email;
  final String pais;
  final int nivel;

  Jugador({
    required this.id,
    required this.nickname,
    required this.nombre,
    required this.email,
    required this.pais,
    required this.nivel,
  });

  factory Jugador.fromJson(Map<String, dynamic> json) => Jugador(
        id: json['id'],
        nickname: json['nickname'],
        nombre: json['nombre'],
        email: json['email'],
        pais: json['pais'],
        nivel: json['nivel'],
      );
}
