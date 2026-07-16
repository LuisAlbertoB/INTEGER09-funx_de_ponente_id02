import 'package:flutter/material.dart';
import '../../services/catalogo_service.dart';

class RecomendadosScreen extends StatefulWidget {
  const RecomendadosScreen({super.key});

  @override
  State<RecomendadosScreen> createState() => _RecomendadosScreenState();
}

class _RecomendadosScreenState extends State<RecomendadosScreen> {
  final CatalogoService _catalogoService = CatalogoService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _recomendaciones = [];

  @override
  void initState() {
    super.initState();
    _fetchRecomendaciones();
  }

  Future<void> _fetchRecomendaciones() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _catalogoService.getRecomendaciones();
      setState(() {
        _recomendaciones = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Para Ti (IA)'),
        backgroundColor: Colors.deepPurple.shade800,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchRecomendaciones,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 16),
            Text('Calculando tu perfil semántico...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error de IA: $_error', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_recomendaciones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Aún no hay recomendaciones',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Evalúa más eventos para que la IA aprenda tus gustos y pueda sugerirte contenido personalizado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.deepPurple.shade50,
          child: Row(
            children: [
              Icon(Icons.psychology, color: Colors.deepPurple.shade800, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Basado en tu historial de interacciones, la IA ha encontrado estos eventos para ti:',
                  style: TextStyle(color: Colors.deepPurple.shade900),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _recomendaciones.length,
            itemBuilder: (context, index) {
              final evento = _recomendaciones[index];
              final score = (evento['ai_score'] ?? 0.0) as double;
              final matchPercentage = (score * 100).toInt();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    // Cabecera con el Match
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade800,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$matchPercentage% Afinidad',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    // Cuerpo de la tarjeta
                    ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        evento['titulo'] ?? 'Evento Recomendado',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          evento['descripcion'] ?? 'Sin descripción',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
