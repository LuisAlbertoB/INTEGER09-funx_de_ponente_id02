import 'package:flutter/material.dart';
import '../../services/catalogo_service.dart';

class InfraestructuraScreen extends StatefulWidget {
  const InfraestructuraScreen({super.key});

  @override
  State<InfraestructuraScreen> createState() => _InfraestructuraScreenState();
}

class _InfraestructuraScreenState extends State<InfraestructuraScreen> with SingleTickerProviderStateMixin {
  final _service = CatalogoService();
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _edificios = [];
  List<Map<String, dynamic>> _aulas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _edificios = await _service.getEdificios();
      _aulas = await _service.getAulas();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infraestructura'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.business), text: 'Edificios'),
            Tab(icon: Icon(Icons.meeting_room), text: 'Aulas'),
          ],
        ),
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
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    // Tab Edificios
                    _edificios.isEmpty
                        ? const Center(child: Text('Sin edificios registrados.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _edificios.length,
                              itemBuilder: (_, i) {
                                final e = _edificios[i];
                                return Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.indigo,
                                      child: Icon(Icons.business, color: Colors.white),
                                    ),
                                    title: Text(e['nombre_edificio']?.toString() ?? 'Edificio ${e['id_edificio']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text('ID: ${e['id_edificio']}'),
                                  ),
                                );
                              },
                            ),
                          ),
                    // Tab Aulas
                    _aulas.isEmpty
                        ? const Center(child: Text('Sin aulas registradas.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _aulas.length,
                              itemBuilder: (_, i) {
                                final a = _aulas[i];
                                return Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.teal,
                                      child: Icon(Icons.meeting_room, color: Colors.white),
                                    ),
                                    title: Text(a['nombre_aula']?.toString() ?? 'Aula ${a['id_aula']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text('Capacidad: ${a['capacidad'] ?? 'N/A'} · Edificio: ${a['id_edificio'] ?? 'N/A'}'),
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
    );
  }
}
