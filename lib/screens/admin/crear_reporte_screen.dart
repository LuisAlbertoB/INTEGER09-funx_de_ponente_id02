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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El título es requerido.')));
      return;
    }
    if (_idAulaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona el aula del incidente.')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte enviado con éxito.')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Levantar Reporte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Reporta cualquier incidente con mobiliario, equipo o instalaciones del aula.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                labelText: 'Título del incidente *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.report_problem_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descripción detallada',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            _loadingAulas
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<int>(
                    value: _idAulaSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación / Aula *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on_outlined),
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
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _enviando ? null : _submit,
                icon: _enviando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_enviando ? 'Enviando...' : 'Enviar Reporte', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
