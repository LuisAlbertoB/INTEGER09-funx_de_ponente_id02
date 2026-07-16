import 'package:flutter/material.dart';
import '../../data/models/conferencia_model.dart';
import '../../services/ponente_service.dart';
import '../eventos/foro_evento_screen.dart';
import '../eventos/solicitar_espacio_screen.dart';
import '../qr/qr_asistencia_screen.dart';
import 'editar_conferencia_screen.dart';

class DetalleConferenciaScreen extends StatefulWidget {
  final ConferenciaModel conferencia;
  const DetalleConferenciaScreen({super.key, required this.conferencia});

  @override
  State<DetalleConferenciaScreen> createState() =>
      _DetalleConferenciaScreenState();
}

class _DetalleConferenciaScreenState extends State<DetalleConferenciaScreen> {
  final _service = PonenteService();

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.w500)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _navegarQR() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrAsistenciaScreen(
          idConferencia: widget.conferencia.idConferencia,
          tituloEvento: widget.conferencia.titulo,
        ),
      ),
    );
  }

  void _navegarForo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForoEventoScreen(
          idEvento: widget.conferencia.idConferencia,
          tituloEvento: widget.conferencia.titulo,
        ),
      ),
    );
  }

  void _navegarSolicitarEspacio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SolicitarEspacioScreen(
          idEvento: widget.conferencia.idConferencia,
          tituloEvento: widget.conferencia.titulo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conferencia;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.titulo, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditarConferenciaScreen(
                    idConferencia: c.idConferencia,
                    tituloActual: c.titulo,
                    descripcionActual: c.descripcion,
                    tematicaActual: c.tematica,
                    nivelActual: c.nivelAcademicoObjetivo,
                    duracionActual: c.duracionEstimadaMin,
                  ),
                ),
              );
              if (updated == true && mounted) Navigator.pop(context, true);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Acciones rápidas ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _accionBtn(
                    icon: Icons.qr_code_rounded,
                    label: 'QR Asistencia',
                    color: Colors.deepPurple,
                    onTap: _navegarQR,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _accionBtn(
                    icon: Icons.forum_outlined,
                    label: 'Comunidad',
                    color: Colors.teal,
                    onTap: _navegarForo,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _accionBtn(
                    icon: Icons.meeting_room_outlined,
                    label: 'Pedir Aula',
                    color: Colors.orange,
                    onTap: _navegarSolicitarEspacio,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Información General ──────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Información General',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Divider(),
                    _row('Título', c.titulo),
                    if (c.descripcion != null)
                      _row('Descripción', c.descripcion!),
                    if (c.tematica != null) _row('Temática', c.tematica!),
                    _row('Nivel objetivo', c.nivelAcademicoObjetivo),
                    _row('Duración estimada', '${c.duracionEstimadaMin} min'),
                    _row('Estado', c.estado == 1 ? '🟢 Activa' : '🔴 Inactiva'),
                    _row('ID Actividad', '${c.idActividad}'),
                    _row('ID Periodo', '${c.idPeriodo}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Materiales ───────────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Materiales de Apoyo',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Usa el servidor o Postman para subir PDF, PPTX y otros archivos a esta conferencia.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
