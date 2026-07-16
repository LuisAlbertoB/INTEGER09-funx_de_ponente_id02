import 'package:flutter/material.dart';
import '../../services/event_service.dart';

/// Formulario de evaluación post-evento.
/// El schema define calificacion como Decimal(2,1) → escala 0.0 a 5.0.
/// La UI muestra estrellas 1-5 y se mapea directamente.
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

  // Escala 1-5 estrellas (Decimal(2,1) en el servidor: 0.0 a 5.0)
  int _estrellas = 4;
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
      // El servidor acepta calificacion como Decimal(2,1) → enviamos el valor directo (1.0-5.0)
      await _service.submitEvaluacion(
        idEvento: widget.idEvento,
        calificacion: _estrellas,          // 1-5, compatible con Decimal(2,1)
        porcentajeSatisfaccion: _satisfaccion.round(), // 0-100
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
                  'Tu retroalimentación alimenta el análisis de sentimiento BERT del sistema.',
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
      appBar: AppBar(title: const Text('Evaluar Evento')),
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

            // ── Calificación con estrellas ────────────────────────────────
            _sectionTitle('⭐ Calificación (1 - 5 estrellas)'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _estrellas = star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      star <= _estrellas ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 44,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                _labelEstrellas(_estrellas),
                style: TextStyle(
                  color: Colors.deepPurple.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
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

  String _labelEstrellas(int n) {
    switch (n) {
      case 1: return 'Muy malo';
      case 2: return 'Regular';
      case 3: return 'Aceptable';
      case 4: return 'Bueno';
      case 5: return 'Excelente';
      default: return '';
    }
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );
}
