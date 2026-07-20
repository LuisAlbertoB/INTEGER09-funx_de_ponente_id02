import 'package:flutter/material.dart';
import '../eventos/foro_evento_screen.dart';
import '../eventos/evaluacion_evento_screen.dart';

/// Pantalla de aterrizaje que se abre al escanear el QR de una conferencia.
/// Presenta tabs de Comunidad y Evaluación sobre el mismo evento.
/// Simula el "control de asistencia": quien escaneó, interactúa con los
/// formularios de minería de datos.
class QrLandingScreen extends StatefulWidget {
  final int idConferencia;
  final String tituloEvento;

  const QrLandingScreen({
    super.key,
    required this.idConferencia,
    required this.tituloEvento,
  });

  @override
  State<QrLandingScreen> createState() => _QrLandingScreenState();
}

class _QrLandingScreenState extends State<QrLandingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Acceso por QR', style: TextStyle(fontSize: 14)),
            Text(
              widget.tituloEvento,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepPurple,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.forum_outlined), text: 'Comunidad'),
            Tab(icon: Icon(Icons.star_outline_rounded), text: 'Evaluar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ForoEventoScreen(
            idEvento: widget.idConferencia,
            tituloEvento: widget.tituloEvento,
          ),
          EvaluacionEventoScreen(
            idEvento: widget.idConferencia,
            tituloEvento: widget.tituloEvento,
          ),
        ],
      ),
    );
  }
}
