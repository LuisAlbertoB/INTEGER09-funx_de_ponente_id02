import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  bool _uploading = false;

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

  // ── Subida de materiales real usando file_picker + multipart ───────────
  Future<void> _subirMaterial() async {
    // 1. Mostrar diálogo para capturar el título y tipo antes de seleccionar archivo
    String titulo = '';
    String tipo = 'pdf';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Subir Material de Apoyo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Título del material *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => titulo = v.trim(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de archivo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                  DropdownMenuItem(value: 'pptx', child: Text('PowerPoint')),
                  DropdownMenuItem(value: 'video', child: Text('Video')),
                  DropdownMenuItem(value: 'imagen', child: Text('Imagen')),
                  DropdownMenuItem(value: 'otro', child: Text('Otro')),
                ],
                onChanged: (v) => setDialogState(() => tipo = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: titulo.isNotEmpty
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurple),
              child: const Text('Seleccionar archivo'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    // 2. Abrir el selector de archivos nativo del dispositivo
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;

    final filePath = result.files.single.path!;

    setState(() => _uploading = true);

    try {
      // 3. Llamar al servicio existente (multipart/form-data al servidor)
      await _service.uploadMaterial(
        idConferencia: widget.conferencia.idConferencia,
        tituloMaterial: titulo,
        tipoArchivo: tipo,
        filePath: filePath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Material subido exitosamente.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '❌ ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
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

            // ── Materiales de Apoyo ──────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Materiales de Apoyo',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Botón de subida real
                        _uploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : TextButton.icon(
                                onPressed: _subirMaterial,
                                icon: const Icon(Icons.upload_file,
                                    color: Colors.deepPurple),
                                label: const Text(
                                  'Subir archivo',
                                  style: TextStyle(color: Colors.deepPurple),
                                ),
                              ),
                      ],
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Toca "Subir archivo" para agregar PDF, PPTX, imágenes o videos a esta conferencia.',
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
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
