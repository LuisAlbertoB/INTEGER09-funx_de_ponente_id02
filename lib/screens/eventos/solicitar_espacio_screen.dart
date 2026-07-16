import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/event_service.dart';
import '../../core/constants/api_constants.dart';
import '../../services/storage_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Formulario para que el Ponente solicite un aula para su conferencia.
/// Consume POST /api/eventos/:idEvento/solicitar-espacio/:idEspacio
/// Campos requeridos: fecha_inicio, fecha_final (ISO 8601)
class SolicitarEspacioScreen extends StatefulWidget {
  final int idEvento;
  final String tituloEvento;

  const SolicitarEspacioScreen({
    super.key,
    required this.idEvento,
    required this.tituloEvento,
  });

  @override
  State<SolicitarEspacioScreen> createState() => _SolicitarEspacioScreenState();
}

class _SolicitarEspacioScreenState extends State<SolicitarEspacioScreen> {
  final _service = EventService();
  final _motivoCtrl = TextEditingController();
  final _storage = StorageService();

  List<Map<String, dynamic>> _aulas = [];
  int? _idAulaSeleccionada;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _loadingAulas = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _loadAulas();
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAulas() async {
    try {
      final token = await _storage.getToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aulas}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _aulas = data.cast<Map<String, dynamic>>();
          _loadingAulas = false;
        });
      } else {
        if (mounted) setState(() => _loadingAulas = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAulas = false);
    }
  }

  /// Selector de fecha+hora robusto: primero fecha, luego hora, luego combina.
  Future<DateTime?> _pickDateTime(DateTime? initialValue) async {
    final now = DateTime.now();
    final initial = initialValue ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _selectFechaInicio() async {
    final result = await _pickDateTime(_fechaInicio);
    if (result != null && mounted) {
      setState(() => _fechaInicio = result);
    }
  }

  Future<void> _selectFechaFin() async {
    final result = await _pickDateTime(_fechaFin ?? _fechaInicio);
    if (result != null && mounted) {
      setState(() => _fechaFin = result);
    }
  }

  Future<void> _submit() async {
    if (_idAulaSeleccionada == null) {
      _snack('Selecciona un aula.', Colors.orange);
      return;
    }
    if (_fechaInicio == null || _fechaFin == null) {
      _snack('Selecciona las fechas de inicio y fin.', Colors.orange);
      return;
    }
    if (_fechaFin!.isBefore(_fechaInicio!)) {
      _snack('La fecha de fin debe ser posterior al inicio.', Colors.red);
      return;
    }

    setState(() => _enviando = true);
    try {
      await _service.solicitarEspacio(
        idEvento: widget.idEvento,
        idEspacio: _idAulaSeleccionada!,
        fechaInicio: _fechaInicio!,
        fechaFinal: _fechaFin!,
        motivo: _motivoCtrl.text.trim().isEmpty ? null : _motivoCtrl.text.trim(),
      );
      if (mounted) {
        _snack('✅ Solicitud enviada. Queda pendiente de aprobación.', Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        _snack(e.toString().replaceFirst('Exception: ', ''), Colors.red);
      }
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  String _fmt(DateTime dt) =>
      DateFormat('dd/MM/yyyy  HH:mm', 'es').format(dt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Espacio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.deepPurple.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, color: Colors.deepPurple.shade400),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.tituloEvento,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Selector de Aula ─────────────────────────────────────────
            const Text('Seleccionar Aula *',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _loadingAulas
                ? const Center(child: CircularProgressIndicator())
                : _aulas.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'No se pudieron cargar las aulas. Verifica la conexión.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      )
                    : DropdownButtonFormField<int>(
                        value: _idAulaSeleccionada,
                        decoration: InputDecoration(
                          hintText: 'Elige un espacio disponible',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _aulas.map((a) {
                          final nombre = a['nombre_aula']?.toString() ??
                              a['nombre']?.toString() ??
                              'Aula ${a['id_aula']}';
                          final capacidad = a['capacidad'];
                          return DropdownMenuItem<int>(
                            value: a['id_aula'] as int,
                            child: Text(
                              capacidad != null
                                  ? '$nombre  (cap. $capacidad)'
                                  : nombre,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _idAulaSeleccionada = v),
                      ),
            const SizedBox(height: 20),

            // ── Fechas ───────────────────────────────────────────────────
            const Text('Fecha y hora de inicio *',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _dateTile(
              label: _fechaInicio != null ? _fmt(_fechaInicio!) : 'Toca para seleccionar',
              hasValue: _fechaInicio != null,
              onTap: _selectFechaInicio,
            ),
            const SizedBox(height: 16),
            const Text('Fecha y hora de fin *',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _dateTile(
              label: _fechaFin != null ? _fmt(_fechaFin!) : 'Toca para seleccionar',
              hasValue: _fechaFin != null,
              onTap: _selectFechaFin,
            ),
            const SizedBox(height: 20),

            // ── Motivo ───────────────────────────────────────────────────
            const Text('Motivo (opcional)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _motivoCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe brevemente el uso del espacio...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Botón de Envío ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _enviando ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _enviando ? 'Enviando solicitud...' : 'Enviar solicitud',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'La solicitud quedará pendiente hasta que un administrador la apruebe.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required bool hasValue,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: hasValue ? Colors.deepPurple.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: hasValue
              ? Border.all(color: Colors.deepPurple.shade200)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: hasValue ? Colors.deepPurple : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: hasValue ? Colors.deepPurple.shade700 : Colors.grey.shade600,
                fontSize: 15,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
