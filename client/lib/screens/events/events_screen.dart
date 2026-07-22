import 'package:flutter/material.dart';
import '../../services/event_service.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventService _eventService = EventService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _eventos = [];
  int _currentPage = 1;
  bool _hasMore = true;

  // Filtros
  int? _estadoFilter;
  String? _nivelFilter;

  @override
  void initState() {
    super.initState();
    _fetchEventos();
  }

  Future<void> _fetchEventos({bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMore || _isLoading) return;
      _currentPage++;
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _eventos.clear();
      });
    }

    try {
      final result = await _eventService.getEventos(
        page: _currentPage,
        limit: 15,
        estado: _estadoFilter,
        nivelAcademicoObjetivo: _nivelFilter,
      );
      
      final newEventos = result['eventos'] as List<dynamic>;
      
      setState(() {
        if (loadMore) {
          _eventos.addAll(newEventos);
        } else {
          _eventos = newEventos;
        }
        _hasMore = newEventos.length == 15;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onFilterEstado(int? estado) {
    _estadoFilter = estado;
    _fetchEventos();
  }

  void _onFilterNivel(String? nivel) {
    _nivelFilter = nivel;
    _fetchEventos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Todos los Eventos', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading && _eventos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _eventos.isEmpty
                        ? const Center(child: Text('No se encontraron eventos.'))
                        : RefreshIndicator(
                            onRefresh: () => _fetchEventos(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _eventos.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _eventos.length) {
                                  _fetchEventos(loadMore: true);
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return _buildEventoCard(_eventos[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.filter_list, color: Colors.grey),
            const SizedBox(width: 12),
            _buildChip('Todos', _estadoFilter == null, () => _onFilterEstado(null)),
            const SizedBox(width: 8),
            _buildChip('Activos', _estadoFilter == 1, () => _onFilterEstado(1)),
            const SizedBox(width: 8),
            _buildChip('Borradores', _estadoFilter == 0, () => _onFilterEstado(0)),
            const SizedBox(width: 16),
            Container(width: 1, height: 24, color: Colors.grey.shade300),
            const SizedBox(width: 16),
            _buildChip('Ambos Niveles', _nivelFilter == null, () => _onFilterNivel(null)),
            const SizedBox(width: 8),
            _buildChip('Licenciatura', _nivelFilter == 'licenciatura', () => _onFilterNivel('licenciatura')),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade100,
      onPressed: onTap,
    );
  }

  Widget _buildEventoCard(dynamic evento) {
    final act = evento['actividad']?['titulo_actividad'] ?? 'Evento';
    final ponente = evento['ponente']?['nombre_completo'] ?? 'Desconocido';
    final titulo = evento['titulo'] ?? 'Sin Título';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(eventId: evento['id_conferencia']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      act,
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    evento['estado'] == 1 ? Icons.check_circle : Icons.edit_document,
                    color: evento['estado'] == 1 ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(ponente, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}