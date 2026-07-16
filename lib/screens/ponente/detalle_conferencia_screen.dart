import 'package:flutter/material.dart';
import '../../data/models/conferencia_model.dart';
import '../../services/ponente_service.dart';
import 'editar_conferencia_screen.dart';

class DetalleConferenciaScreen extends StatefulWidget {
  final ConferenciaModel conferencia;
  const DetalleConferenciaScreen({super.key, required this.conferencia});

  @override
  State<DetalleConferenciaScreen> createState() => _DetalleConferenciaScreenState();
}

class _DetalleConferenciaScreenState extends State<DetalleConferenciaScreen> {
  final _service = PonenteService();
  bool _uploading = false;
  final _tituloMaterialCtrl = TextEditingController();
  String _tipoArchivo = 'pdf';

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    _tituloMaterialCtrl.clear();
    _tipoArchivo = 'pdf';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Subir Material'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _tituloMaterialCtrl,
                decoration: const InputDecoration(labelText: 'Título del material', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _tipoArchivo,
                decoration: const InputDecoration(labelText: 'Tipo de archivo', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                  DropdownMenuItem(value: 'pptx', child: Text('PPTX')),
                  DropdownMenuItem(value: 'docx', child: Text('DOCX')),
                ],
                onChanged: (v) => setDialogState(() => _tipoArchivo = v!),
              ),
              const SizedBox(height: 12),
              const Text(
                'Nota: La subida de archivos desde el celular requiere el paquete file_picker. '
                'Por ahora, usa Postman para subir materiales al servidor.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conferencia;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
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
              if (updated == true && mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadDialog,
        icon: const Icon(Icons.upload_file),
        label: const Text('Material'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Información General', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Divider(),
                    _row('Título', c.titulo),
                    if (c.descripcion != null) _row('Descripción', c.descripcion!),
                    if (c.tematica != null) _row('Temática', c.tematica!),
                    _row('Nivel objetivo', c.nivelAcademicoObjetivo),
                    _row('Duración estimada', '${c.duracionEstimadaMin} min'),
                    _row('Estado', c.estado == 1 ? 'Activa' : 'Inactiva'),
                    _row('ID Actividad', '${c.idActividad}'),
                    _row('ID Periodo', '${c.idPeriodo}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Materiales de Apoyo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Presiona el botón "Material" para subir archivos de apoyo (PDF, PPTX).',
                        style: TextStyle(color: Colors.grey),
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
}
