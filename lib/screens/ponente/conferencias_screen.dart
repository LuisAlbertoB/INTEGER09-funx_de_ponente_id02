import 'package:flutter/material.dart';
import '../../data/models/conferencia_model.dart';
import '../../services/ponente_service.dart';
import 'crear_evento_screen.dart';
import 'detalle_conferencia_screen.dart';

class ConferenciasScreen extends StatefulWidget {
  const ConferenciasScreen({super.key});

  @override
  State<ConferenciasScreen> createState() => _ConferenciasScreenState();
}

class _ConferenciasScreenState extends State<ConferenciasScreen> {
  final _service = PonenteService();
  List<ConferenciaModel> _conferencias = [];
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
      _conferencias = await _service.getMisConferencias();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar conferencia'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteConferencia(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Conferencias')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CrearEventoScreen()),
          );
          if (created == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
        backgroundColor: Colors.deepPurple,
      ),
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
              : _conferencias.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic_off, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No tienes conferencias aún.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _conferencias.length,
                        itemBuilder: (_, i) {
                          final c = _conferencias[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.deepPurple,
                                child: Icon(Icons.mic, color: Colors.white),
                              ),
                              title: Text(c.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${c.nivelAcademicoObjetivo} · ${c.duracionEstimadaMin} min',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'delete') _delete(c.idConferencia);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                ],
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetalleConferenciaScreen(conferencia: c),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
