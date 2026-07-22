import 'package:flutter/material.dart';
import '../../services/ponente_service.dart';

class EditarConferenciaScreen extends StatefulWidget {
  final int idConferencia;
  final String tituloActual;
  final String? descripcionActual;
  final String? tematicaActual;
  final String nivelActual;
  final int duracionActual;

  const EditarConferenciaScreen({
    super.key,
    required this.idConferencia,
    required this.tituloActual,
    this.descripcionActual,
    this.tematicaActual,
    required this.nivelActual,
    required this.duracionActual,
  });

  @override
  State<EditarConferenciaScreen> createState() => _EditarConferenciaScreenState();
}

class _EditarConferenciaScreenState extends State<EditarConferenciaScreen> {
  final _service = PonenteService();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _tematicaCtrl;
  late String _nivel;
  late int _duracion;
  bool _loading = false;

  final List<String> _nivelesOpts = ['undergraduate', 'postgraduate', 'ambos'];

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.tituloActual);
    _descCtrl = TextEditingController(text: widget.descripcionActual ?? '');
    _tematicaCtrl = TextEditingController(text: widget.tematicaActual ?? '');
    _nivel = widget.nivelActual;
    _duracion = widget.duracionActual;
  }

  Future<void> _submit() async {
    if (_tituloCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título es requerido.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _service.updateConferencia(widget.idConferencia, {
        'titulo': _tituloCtrl.text.trim(),
        'descripcion': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'tematica': _tematicaCtrl.text.trim().isEmpty ? null : _tematicaCtrl.text.trim(),
        'nivel_academico_objetivo': _nivel,
        'duracion_estimada_min': _duracion,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Conferencia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(labelText: 'Título *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _tematicaCtrl,
              decoration: const InputDecoration(labelText: 'Temática', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _nivel,
              decoration: const InputDecoration(labelText: 'Nivel académico objetivo', border: OutlineInputBorder()),
              items: _nivelesOpts.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
              onChanged: (v) => setState(() => _nivel = v!),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('Duración (min):'),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _duracion.toDouble(),
                    min: 30,
                    max: 240,
                    divisions: 14,
                    label: '$_duracion min',
                    onChanged: (v) => setState(() => _duracion = v.round()),
                  ),
                ),
                Text('$_duracion'),
              ],
            ),
            const SizedBox(height: 28),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
                  ),
          ],
        ),
      ),
    );
  }
}
