import 'package:flutter/material.dart';
import '../../services/event_service.dart';

/// Formulario de evaluación post-evento.
/// Al enviar, el servidor de Node.js pasa el comentario escrito a BERT (Fire & Forget)
/// para análisis de sentimiento en segundo plano.
class EvaluacionEventoScreen extends StatefulWidget {
  final int idEvento;
  final String tituloEvento;

  const EvaluacionEventoScreen({
    super.key,
    required this.idEvento,
    required this.tituloEvento,
  });

  @override
  State<EvaluacionEventoScreen> createState() => _EvaluacionEventoScreenState();
}

class _EvaluacionEventoScreenState extends State<EvaluacionEventoScreen> {
  final _service = EventService();
  final _comentarioCtrl = TextEditingController();

  double _calificacion = 7;
  double _satisfaccion = 70;
  bool _loading = false;
  bool _enviado = false;

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await _service.submitEvaluacion(
        idEvento: widget.idEvento,
        calificacion: _calificacion.round(),
        porcentajeSatisfaccion: _satisfaccion.round(),
        comentarioEscrito: _comentarioCtrl.text.trim().isEmpty
            ? null
            : _comentarioCtrl.text.trim(),
      );
      if (mounted) setState(() => _enviado = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      final bool yaEvaluado = msg.toLowerCase().contains('ya has evaluado');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(yaEvaluado ? '⚠️ Ya evaluaste este evento.' : msg),
          backgroundColor: yaEvaluado ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_enviado) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 80),
                const SizedBox(height: 20),
                Text(
                  '¡Gracias por evaluar!',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tu retroalimentación ayuda a mejorar futuros eventos y alimenta nuestro sistema de inteligencia artificial.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluar Evento'),
        backgroundColor: colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade700,
                    Colors.deepPurple.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    widget.tituloEvento,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tu opinión alimenta el análisis de IA',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Calificación ─────────────────────────────────────────────
            _sectionTitle('⭐ Calificación general'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${_calificacion.round()}',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const Text(
                  ' / 10',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
              ],
            ),
            Slider(
              value: _calificacion,
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: Colors.deepPurple,
              label: '${_calificacion.round()} ⭐',
              onChanged: (v) => setState(() => _calificacion = v),
            ),
            const SizedBox(height: 24),

            // ── Satisfacción ─────────────────────────────────────────────
            _sectionTitle('😊 Nivel de satisfacción'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${_satisfaccion.round()}%',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            Slider(
              value: _satisfaccion,
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: Colors.teal,
              label: '${_satisfaccion.round()}%',
              onChanged: (v) => setState(() => _satisfaccion = v),
            ),
            const SizedBox(height: 24),

            // ── Comentario Escrito ────────────────────────────────────────
            _sectionTitle('💬 Comentario libre'),
            const SizedBox(height: 4),
            Text(
              'Este texto es analizado por IA para detectar el sentimiento de tu experiencia.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _comentarioCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Escribe tu experiencia con el evento... (opcional pero valioso)',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 36),

            // ── Botón de Envío ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _loading ? 'Enviando...' : 'Enviar evaluación',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );
}
