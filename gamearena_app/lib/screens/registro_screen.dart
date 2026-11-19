import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Recibe la MISMA instancia de ApiService de la pantalla anterior,
/// así el token del login admin también aplica aquí.
class RegistroScreen extends StatefulWidget {
  final ApiService api;
  const RegistroScreen({super.key, required this.api});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _enviando = false;

  final _nickname = TextEditingController();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _pais = TextEditingController();

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final jugador = await widget.api.registrarJugador(
        nickname: _nickname.text.trim(),
        nombre: _nombre.text.trim(),
        email: _email.text.trim(),
        pais: _pais.text.trim(),
        nivel: 1,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jugador "${jugador.nickname}" registrado')),
      );
    } on ApiException catch (e) {
      // 403: la API exige admin — se muestra el mensaje del backend
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${e.status}: ${e.message}'),
          backgroundColor: e.status == 403 ? Colors.orange : Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo conectar con el servidor')),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de jugador')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _nickname,
              decoration: const InputDecoration(labelText: 'Nickname', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              validator: (v) => (v == null || !v.contains('@') || !v.contains('.')) ? 'Email inválido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pais,
              decoration: const InputDecoration(labelText: 'País', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _enviando ? null : _registrar,
                icon: _enviando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_enviando ? 'Enviando...' : 'Registrarme'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nota: la creación de jugadores requiere usuario administrador (API Django). '
              'Sin token el servidor responde 403.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ),
    );
  }
}
