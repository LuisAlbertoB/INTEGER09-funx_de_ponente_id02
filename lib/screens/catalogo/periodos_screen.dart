import 'package:flutter/material.dart';
import '../../services/catalogo_service.dart';

class PeriodosScreen extends StatefulWidget {
  const PeriodosScreen({super.key});

  @override
  State<PeriodosScreen> createState() => _PeriodosScreenState();
}

class _PeriodosScreenState extends State<PeriodosScreen> {
  final _service = CatalogoService();
  List<Map<String, dynamic>> _periodos = [];
  Map<String, dynamic>? _periodoActivo;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _periodos = await _service.getPeriodos();
      _periodoActivo = await _service.getPeriodoActivo();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Periodos Académicos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_periodoActivo != null) ...[
                        Card(
                          color: Colors.green.shade50,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.check, color: Colors.white),
                            ),
                            title: Text(
                              _periodoActivo!['nombre_clave']?.toString() ?? 'Periodo Activo',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text('Periodo actualmente activo'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Todos los periodos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 8),
                      ],
                      ..._periodos.map((p) {
                        final isActivo = _periodoActivo != null &&
                            p['id_periodo'] == _periodoActivo!['id_periodo'];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isActivo ? Colors.green : Colors.blueGrey,
                              child: Icon(
                                isActivo ? Icons.calendar_today : Icons.calendar_month,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              p['nombre_clave']?.toString() ?? 'Periodo ${p['id_periodo']}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('ID: ${p['id_periodo']}'),
                            trailing: isActivo
                                ? const Chip(label: Text('Activo', style: TextStyle(color: Colors.white, fontSize: 11)), backgroundColor: Colors.green)
                                : null,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}
