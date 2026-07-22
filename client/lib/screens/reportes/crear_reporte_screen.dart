import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/admin_service.dart';
import '../../services/storage_service.dart';
import '../../core/constants/api_constants.dart';

class CrearReporteScreen extends StatefulWidget {
  const CrearReporteScreen({super.key});

  @override
  State<CrearReporteScreen> createState() => _CrearReporteScreenState();
}

class _CrearReporteScreenState extends State<CrearReporteScreen> {
  final AdminService _adminService = AdminService();
  final StorageService _storage = StorageService();

  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<Map<String, dynamic>> _aulas = [];
  int? _idAulaSeleccionada;
  bool _loadingAulas = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _loadAulas();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
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

  Future<void> _submit() async {
    if (_tituloCtrl.text.trim().isEmpty) {
      _showError('El título es requerido.');
      return;
    }
    if (_idAulaSeleccionada == null) {
      _showError('Selecciona la ubicación del incidente.');
      return;
    }

    setState(() => _enviando = true);
    try {
      await _adminService.crearReporte(
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descCtrl.text.trim(),
        idAula: _idAulaSeleccionada!,
      );
      if (mounted) {
        _showSuccess('Reporte enviado con éxito. La IA agrupará este incidente.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        _showError(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ],
      ),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Incidente', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange.shade800, Colors.red.shade700],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF8FAFC), // Fondo gris muy claro
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Cabecera de la pantalla ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.support_agent_rounded, size: 32, color: Colors.orange.shade700),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Asistencia Inteligente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                          SizedBox(height: 4),
                          Text(
                            'La IA organizará y canalizará automáticamente este incidente al área correspondiente.',
                            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.3),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text('Detalles del Problema', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
              const SizedBox(height: 16),

              // --- Campo Título ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: TextField(
                  controller: _tituloCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título del incidente *',
                    hintText: 'Ej. "Proyector dañado" o "Aire acondicionado no enfría"',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    prefixIcon: Icon(Icons.report_problem_outlined, color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Campo Ubicación ---
              _loadingAulas
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
                      ),
                      child: DropdownButtonFormField<int>(
                        value: _idAulaSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Ubicación / Aula *',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          prefixIcon: Icon(Icons.location_on_outlined, color: Colors.redAccent),
                        ),
                        items: _aulas.map((a) {
                          final nombre = a['nombre_aula']?.toString() ?? a['nombre']?.toString() ?? 'Aula ${a['id_aula']}';
                          return DropdownMenuItem<int>(
                            value: a['id_aula'] as int,
                            child: Text(nombre),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _idAulaSeleccionada = v),
                      ),
                    ),
              const SizedBox(height: 16),

              // --- Campo Descripción ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descripción detallada',
                    hintText: 'Describe el problema con el mayor detalle posible para que la Inteligencia Artificial lo pueda agrupar correctamente...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // --- Botón de Envío ---
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade700, Colors.red.shade600],
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _enviando ? null : _submit,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_enviando)
                          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        else
                          const Icon(Icons.send_rounded, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          _enviando ? 'Enviando...' : 'Enviar Reporte',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
