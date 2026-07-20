import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/qr_service.dart';

/// Vista exclusiva del Ponente: muestra el QR de asistencia de su conferencia.
/// El QR codifica: unievent://evento/{idConferencia}
/// Los asistentes lo escanean con QrScannerScreen para acceder al foro + evaluación.
class QrAsistenciaScreen extends StatelessWidget {
  final int idConferencia;
  final String tituloEvento;

  const QrAsistenciaScreen({
    super.key,
    required this.idConferencia,
    required this.tituloEvento,
  });

  @override
  Widget build(BuildContext context) {
    final payload = QrService.buildPayload(idConferencia);

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('QR de Asistencia'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Instrucción ──────────────────────────────────────────
              Text(
                'Muestra este código a tus asistentes',
                style: TextStyle(
                  color: Colors.deepPurple.shade200,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ── Código QR ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 240,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF4A148C),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF311B92),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Nombre del evento ─────────────────────────────────────
              Text(
                tituloEvento,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ID Conferencia: #$idConferencia',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // ── Instrucciones para asistentes ─────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
                child: Column(
                  children: [
                    _step('1', 'El asistente abre UniEvents'),
                    const SizedBox(height: 8),
                    _step('2', 'Presiona el ícono 📷 de scanner'),
                    const SizedBox(height: 8),
                    _step('3', 'Escanea este QR con su cámara'),
                    const SizedBox(height: 8),
                    _step('4', 'Accede al foro y llena la evaluación'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(String num, String text) => Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.deepPurple.shade300,
            child: Text(
              num,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      );
}
