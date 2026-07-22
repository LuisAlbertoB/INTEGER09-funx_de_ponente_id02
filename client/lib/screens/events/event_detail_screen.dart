import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/event_service.dart';
import '../../providers/auth_provider.dart';
import '../eventos/solicitar_espacio_screen.dart';
import '../eventos/foro_evento_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventService _eventService = EventService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _evento;

  @override
  void initState() {
    super.initState();
    _fetchEvento();
  }

  Future<void> _fetchEvento() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _eventService.getEventoById(widget.eventId);
      setState(() {
        _evento = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detalle del Evento', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _evento == null
                  ? const Center(child: Text('Evento no encontrado.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(_evento!),
                          const SizedBox(height: 20),
                          _buildInfoSection(_evento!),
                          const SizedBox(height: 30),
                          _buildActionButtons(context, _evento!, user?.idUsuario),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> evento) {
    final titulo = evento['titulo'] ?? 'Sin Título';
    final act = evento['actividad']?['titulo_actividad'] ?? 'Actividad';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            act,
            style: const TextStyle(
              color: Color(0xFF6366F1),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> evento) {
    final descripcion = evento['descripcion'] ?? 'No hay descripción disponible.';
    final ponente = evento['ponente']?['nombre_completo'] ?? 'Desconocido';
    final aula = evento['aula']?['nombre_aula'] ?? 'Por asignar';
    final fecha = evento['fecha_realizada'] != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(evento['fecha_realizada'])) 
        : 'Pendiente';
    final nivel = evento['nivel_academico_objetivo'] ?? 'Ambos';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(descripcion, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          _infoRow(Icons.person_outline, 'Ponente', ponente),
          const SizedBox(height: 12),
          _infoRow(Icons.location_on_outlined, 'Aula', aula),
          const SizedBox(height: 12),
          _infoRow(Icons.calendar_today_outlined, 'Fecha', fecha),
          const SizedBox(height: 12),
          _infoRow(Icons.school_outlined, 'Nivel Académico', nivel.toUpperCase()),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> evento, int? currentUserId) {
    final isPonente = currentUserId == evento['id_ponente'];
    final bool hasAula = evento['id_aula_utilizada'] != null;

    return Column(
      children: [
        if (isPonente) ...[
          const Text('Opciones de Administrador (Ponente)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasAula
                  ? null
                  : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SolicitarEspacioScreen(
                            idEvento: evento['id_conferencia'],
                            tituloEvento: evento['titulo'],
                          ),
                        ),
                      );
                      _fetchEvento(); // Refrescar después de volver
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.meeting_room, color: Colors.white),
              label: Text(
                hasAula ? 'Aula ya asignada / Solicitada' : 'Solicitar Aula',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Implementar subida de materiales en el futuro
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Función de materiales en desarrollo')));
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFF6366F1)),
              ),
              icon: const Icon(Icons.upload_file, color: Color(0xFF6366F1)),
              label: const Text('Subir Material', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ForoEventoScreen(idEvento: evento['id_conferencia']),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981), // Emerald
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.forum, color: Colors.white),
            label: const Text('Ver Foro de la Comunidad', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
