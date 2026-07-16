import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/models/conferencia_model.dart';
import '../../services/ponente_service.dart';

// Pantalla legacy de la plantilla - mantenida como stub
class EventsScreen extends StatelessWidget {
  final UserModel user;
  const EventsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Ver ConferenciasScreen')),
    );
  }
}