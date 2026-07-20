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
        title: const Text('Para Ti (IA)', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple.shade900, Colors.purple.shade700],
            ),
          ),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, color: Colors.deepPurple.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Basado en tus intereses y evaluaciones previas, hemos seleccionado estos eventos especialmente para ti.',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 14,
                    height: 1.4,
                  ),
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

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabecera con el Match (Gradiente vibrante)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '$matchPercentage% Match Contigo',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      // Cuerpo de la tarjeta
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              evento['titulo'] ?? 'Evento Recomendado',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              evento['descripcion'] ?? 'Sin descripción disponible',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  // Próximamente: Ir a detalle
                                },
                                style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
                                icon: const Icon(Icons.visibility, size: 20),
                                label: const Text('Ver Detalles', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
