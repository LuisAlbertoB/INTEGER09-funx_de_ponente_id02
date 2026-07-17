import 'package:flutter/material.dart';
import '../../services/ponente_service.dart';

class CrearEventoScreen extends StatefulWidget {
  const CrearEventoScreen({super.key});

  @override
  State<CrearEventoScreen> createState() => _CrearEventoScreenState();
}

class _CrearEventoScreenState extends State<CrearEventoScreen> {
  final _service = PonenteService();
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tematicaCtrl = TextEditingController();

  String _nivelAcademico = 'ambos';
  int _duracion = 60;
  int? _idActividad;
  int? _idPeriodo;
  bool _loading = false;

  List<Map<String, dynamic>> _actividades = [];
  List<Map<String, dynamic>> _periodos = [];

  final List<String> _nivelesOpts = ['undergraduate', 'postgraduate', 'ambos'];

  @override
  void initState() {
    super.initState();
    _loadCatalogos();
  }

  Future<void> _loadCatalogos() async {
    final acts = await _service.getActividades();
    final pers = await _service.getPeriodos();
    
    if (mounted) {
      setState(() { 
        _actividades = acts; 
        _periodos = pers; 
        
        // Autoseleccionar la opción de "Conferencia" si existe en la base de datos (id: 4 o buscando por nombre)
        if (acts.isNotEmpty) {
          final confOpt = acts.firstWhere((a) => a['titulo_actividad']?.toString().toLowerCase().contains('conferencia') == true || a['id_actividad'] == 4, orElse: () => acts.first);
          _idActividad = confOpt['id_actividad'];
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_tituloCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título es requerido.')),
      );
      return;
    }
    if (_idActividad == null || _idPeriodo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona actividad y periodo.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _service.createConferencia(
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        tematica: _tematicaCtrl.text.trim().isEmpty ? null : _tematicaCtrl.text.trim(),
        nivelAcademicoObjetivo: _nivelAcademico,
        duracionEstimadaMin: _duracion,
        idActividad: _idActividad!,
        idPeriodo: _idPeriodo!,
      );
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
      appBar: AppBar(title: const Text('Nuevo Evento')),
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
              value: _nivelAcademico,
              decoration: const InputDecoration(labelText: 'Nivel académico objetivo', border: OutlineInputBorder()),
              items: _nivelesOpts.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
              onChanged: (v) => setState(() => _nivelAcademico = v!),
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
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              value: _idActividad,
              decoration: const InputDecoration(labelText: 'Actividad *', border: OutlineInputBorder()),
              items: _actividades.map((a) => DropdownMenuItem<int>(
                value: a['id_actividad'] as int,
                child: Text(a['titulo_actividad'] as String),
              )).toList(),
              onChanged: (v) => setState(() => _idActividad = v),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              value: _idPeriodo,
              decoration: const InputDecoration(labelText: 'Periodo *', border: OutlineInputBorder()),
              items: _periodos.map((p) => DropdownMenuItem<int>(
                value: p['id_periodo'] as int,
                child: Text(p['nombre_clave'] as String),
              )).toList(),
              onChanged: (v) => setState(() => _idPeriodo = v),
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
                    child: const Text('Crear Evento', style: TextStyle(fontSize: 16)),
                  ),
          ],
        ),
      ),
    );
  }
}
